#[cfg(feature = "ssr")]
const BACKEND_URL: &str = "http://127.0.0.1:8000";

#[cfg(feature = "ssr")]
#[derive(serde::Deserialize)]
struct SearchParams {
    lyrics: String,
}

#[cfg(feature = "ssr")]
fn encode_path_segment(input: &str) -> String {
    let mut encoded = String::with_capacity(input.len());
    for byte in input.bytes() {
        match byte {
            b'/' => {}
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' => {
                encoded.push(byte as char);
            }
            _ => encoded.push_str(&format!("%{byte:02X}")),
        }
    }
    encoded
}

#[cfg(feature = "ssr")]
async fn proxy_search(
    axum::extract::Query(params): axum::extract::Query<SearchParams>,
) -> Result<impl axum::response::IntoResponse, (axum::http::StatusCode, String)> {
    let url = format!(
        "{BACKEND_URL}/search/{}",
        encode_path_segment(&params.lyrics)
    );
    let response = reqwest::get(url)
        .await
        .map_err(|error| (axum::http::StatusCode::BAD_GATEWAY, error.to_string()))?;
    let status = axum::http::StatusCode::from_u16(response.status().as_u16())
        .unwrap_or(axum::http::StatusCode::BAD_GATEWAY);
    let body = response
        .bytes()
        .await
        .map_err(|error| (axum::http::StatusCode::BAD_GATEWAY, error.to_string()))?;

    Ok((
        status,
        [(axum::http::header::CONTENT_TYPE, "application/json")],
        body,
    ))
}

#[cfg(feature = "ssr")]
#[tokio::main]
async fn main() {
    use axum::routing::get;
    use axum::Router;
    use leptos::logging::log;
    use leptos::prelude::*;
    use leptos_axum::{generate_route_list, LeptosRoutes};
    use lyrics_retriever::app::*;

    let conf = get_configuration(None).unwrap();
    let addr = conf.leptos_options.site_addr;
    let leptos_options = conf.leptos_options;
    // Generate the list of routes in your Leptos App
    let routes = generate_route_list(App);

    let app = Router::new()
        .route("/api/search", get(proxy_search))
        .leptos_routes(&leptos_options, routes, {
            let leptos_options = leptos_options.clone();
            move || shell(leptos_options.clone())
        })
        .fallback(leptos_axum::file_and_error_handler(shell))
        .with_state(leptos_options);

    // run our app with hyper
    // `axum::Server` is a re-export of `hyper::Server`
    log!("listening on http://{}", &addr);
    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app.into_make_service())
        .await
        .unwrap();
}

#[cfg(not(feature = "ssr"))]
pub fn main() {
    // no client-side main function
    // unless we want this to work with e.g., Trunk for pure client-side testing
    // see lib.rs for hydration function instead
}
