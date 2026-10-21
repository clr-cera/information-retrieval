use leptos::prelude::*;
use leptos_meta::{provide_meta_context, MetaTags, Stylesheet};
use leptos_router::{
    components::{Route, Router, Routes},
    StaticSegment,
};
use serde::{Deserialize, Serialize};

const API_URL: &str = "http://localhost:8000";

pub fn shell(options: LeptosOptions) -> impl IntoView {
    view! {
        <!DOCTYPE html>
        <html lang="pt-BR">
            <head>
                <meta charset="utf-8"/>
                <meta name="viewport" content="width=device-width, initial-scale=1"/>
                <AutoReload options=options.clone() />
                <HydrationScripts options/>
                <MetaTags/>
            </head>
            <body>
                <App/>
            </body>
        </html>
    }
}

#[component]
pub fn App() -> impl IntoView {
    // Provides context that manages stylesheets, titles, meta tags, etc.
    provide_meta_context();

    view! {
        <Stylesheet id="leptos" href="/pkg/lyrics_retriever.css"/>

        <div class="app">
            <header class="app-header">
                <h1>"De que música é a letra?"</h1>
                <p class="app-tagline">"Encontre músicas a partir de um trecho da letra."</p>
            </header>

            <Router>
                <main class="app-main">
                    <Routes fallback=|| "Page not found.".into_view()>
                        <Route path=StaticSegment("") view=HomePage/>
                    </Routes>
                </main>
            </Router>
        </div>
    }
}

/// Renders the home page of your application.
#[component]
fn HomePage() -> impl IntoView {
    let (query, set_query) = signal(String::new());
    let (expanded, set_expanded) = signal(None::<usize>);

    let search = Action::new_local(move |lyrics: &String| search_music(lyrics.clone()));

    view! {
        <p class="search-intro">
            "Procure uma música pela letra dela e veja os resultados ranqueados."
        </p>

        <form
            class="search-form"
            on:submit=move |ev| {
                ev.prevent_default();
                let lyrics = query.get();
                if !lyrics.trim().is_empty() {
                    set_expanded.set(None);
                    search.dispatch_local(lyrics);
                }
            }
        >
            <input
                class="search-input"
                type="text"
                placeholder="Digite a letra da música"
                aria-label="Letra da música"
                autocomplete="off"
                prop:value=query
                on:input=move |ev| set_query(event_target_value(&ev))
            />
            <button
                class="search-button"
                type="submit"
                disabled=move || query.get().trim().is_empty() || search.pending().get()
            >
                {move || if search.pending().get() { "Buscando..." } else { "Buscar" }}
            </button>
        </form>

        <Show when=move || search.pending().get()>
            <div class="status status-loading">
                <span class="spinner"></span>
                "Buscando músicas..."
            </div>
        </Show>

        {move || match search.value().get() {
            None => ().into_any(),
            Some(Ok(results)) => {
                let QueryResults {
                    musics,
                    query_processed,
                } = results;
                let count = musics.len();
                view! {
                    <section class="results">
                        <header class="results-header">
                            <h2>"Resultados"</h2>
                            <span class="results-count">{count}" resultados"</span>
                        </header>
                        <p class="results-query">
                            "Consulta processada: " <span>{query_processed}</span>
                        </p>
                        <ul class="results-list">
                            {musics.into_iter().enumerate().map(|(index, music)| {
                                let Music {
                                    title,
                                    artist,
                                    lyrics,
                                    lyrics_processed,
                                    metric,
                                    relevant_terms,
                                } = music;
                                let is_expanded = move || expanded.get() == Some(index);
                                view! {
                                    <li class="result-card" class:expanded=is_expanded>
                                        <button
                                            class="result-toggle"
                                            type="button"
                                            aria-expanded=move || if is_expanded() { "true" } else { "false" }
                                            on:click=move |_| set_expanded.update(|current| {
                                                *current = if *current == Some(index) {
                                                    None
                                                } else {
                                                    Some(index)
                                                };
                                            })
                                        >
                                            <span class="result-rank">{index + 1}</span>
                                            <span class="result-body">
                                                <span class="result-heading">
                                                    <span class="result-title">{title}</span>
                                                    <span class="result-metric" title="Similaridade">
                                                        {format!("{:.2}", metric)}
                                                    </span>
                                                </span>
                                                <span class="result-artist">{artist}</span>
                                            </span>
                                            <span class="result-chevron" aria-hidden="true"></span>
                                        </button>
                                        <Show when=is_expanded>
                                            <div class="result-details">
                                                <div class="result-section">
                                                    <h4>"Letra"</h4>
                                                    <p class="result-lyrics">{lyrics.clone()}</p>
                                                </div>
                                                <div class="result-section">
                                                    <h4>"Letra processada"</h4>
                                                    <p class="result-lyrics">{lyrics_processed.clone()}</p>
                                                </div>
                                                <div class="result-section">
                                                    <h4>"Termos relevantes"</h4>
                                                    {{
                                                        let terms = relevant_terms.clone();
                                                        if terms.is_empty() {
                                                            view! {
                                                                <p class="result-empty">
                                                                    "Nenhum termo relevante."
                                                                </p>
                                                            }.into_any()
                                                        } else {
                                                            view! {
                                                                <ul class="result-terms">
                                                                    {terms.into_iter().map(|(term, score)| view! {
                                                                        <li class="result-term">
                                                                            <span class="result-term-name">{term}</span>
                                                                            <span class="result-term-score">
                                                                                {format!("{:.2}", score)}
                                                                            </span>
                                                                        </li>
                                                                    }).collect_view()}
                                                                </ul>
                                                            }.into_any()
                                                        }
                                                    }}
                                                </div>
                                            </div>
                                        </Show>
                                    </li>
                                }
                            }).collect_view()}
                        </ul>
                    </section>
                }.into_any()
            }
            Some(Err(error)) => view! {
                <div class="status status-error">
                    <strong>"Não foi possível buscar as músicas."</strong>
                    <span>{error}</span>
                </div>
            }.into_any(),
        }}
    }
}

fn use_mock_api() -> bool {
    matches!(option_env!("LYRICS_API_MOCK"), Some("1") | Some("true"))
}

async fn search_music(lyrics: String) -> Result<QueryResults, String> {
    if use_mock_api() {
        query_music_by_lyrics_mock(lyrics).await
    } else {
        query_music_by_lyrics(lyrics).await
    }
}

async fn query_music_by_lyrics(lyrics: String) -> Result<QueryResults, String> {
    let response = reqwest::Client::new()
        .get(format!("{API_URL}/search"))
        .query(&[("lyrics", lyrics.as_str())])
        .send()
        .await
        .map_err(|e| e.to_string())?
        .error_for_status()
        .map_err(|e| e.to_string())?;

    let musics = response
        .json::<Vec<Music>>()
        .await
        .map_err(|e| e.to_string())?;

    Ok(QueryResults {
        musics,
        query_processed: lyrics,
    })
}

async fn query_music_by_lyrics_mock(lyrics: String) -> Result<QueryResults, String> {
    let musics = vec![
        Music {
            title: "Música de exemplo 1".into(),
            artist: "Artista A".into(),
            lyrics: lyrics.clone(),
            lyrics_processed: lyrics.to_lowercase(),
            metric: 0.95,
            relevant_terms: vec![
                ("amor".into(), 0.91),
                ("saudade".into(), 0.84),
                ("coração".into(), 0.72),
            ],
        },
        Music {
            title: "Música de exemplo 2".into(),
            artist: "Artista B".into(),
            lyrics: lyrics.clone(),
            lyrics_processed: lyrics.to_lowercase(),
            metric: 0.82,
            relevant_terms: vec![
                ("noite".into(), 0.88),
                ("sonho".into(), 0.75),
                ("estrada".into(), 0.61),
            ],
        },
        Music {
            title: "Música de exemplo 3".into(),
            artist: "Artista C".into(),
            lyrics: lyrics.clone(),
            lyrics_processed: lyrics.to_lowercase(),
            metric: 0.71,
            relevant_terms: vec![
                ("tempo".into(), 0.83),
                ("lembrança".into(), 0.69),
                ("cidade".into(), 0.58),
            ],
        },
    ];

    Ok(QueryResults {
        musics,
        query_processed: lyrics,
    })
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct QueryResults {
    musics: Vec<Music>,
    query_processed: String,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct Music {
    title: String,
    artist: String,
    lyrics: String,
    lyrics_processed: String,
    metric: f32,
    relevant_terms: Vec<(String, f32)>,
}
