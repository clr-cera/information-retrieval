import ast
from pathlib import Path
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import re

RESULTS_DIR = Path("result")
PLOTS_DIR = Path("plots")

def plot_precision_recall_probabilistic_var():
    """
    Plots Precision vs Recall curves (cutoffs @1 to @10) for each pipeline group of probabilistic model variants.
    """
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    PLOTS_DIR.mkdir(parents=True, exist_ok=True)
    
    files = list(Path(RESULTS_DIR).glob('top_10_docs_*.txt'))
    pipeline_groups = {}

    for file in files:
        filename = file.name.replace("top_10_docs_", "").replace(".txt", "")
        
        if "Probabilistic" in filename:
            group, model_part = filename.split("Probabilistic_", 1)
            k_val = model_part.split("_")[0]
            b_val = model_part.split("_")[1]
            model = f"Prob.(k={k_val[1:]},b={b_val[1:]})"
        else:
            continue

        if group not in pipeline_groups:
            pipeline_groups[group] = {}

        query_precisions = []
        query_recalls = []

        # Read file lines (1 line == 1 query)
        with file.open('r') as f:
            for line in f:
                if ":" not in line:
                    continue
                try:
                    items = ast.literal_eval(line.split(":")[1].strip())
                except Exception:
                    continue
                
                if not items:
                    continue

                total_relevant = sum(1 for _, _, rel in items if rel == 1)
                
                p_k_list = []
                r_k_list = []
                relevant_so_far = 0
                
                # Calculate P@k/R@k for each k (1 to len(items))
                for k, (doc_id, score, rel) in enumerate(items, 1):
                    if rel == 1:
                        relevant_so_far += 1
                    
                    p_k = relevant_so_far / k
                    r_k = (relevant_so_far / total_relevant) if total_relevant > 0 else 0.0
                    
                    p_k_list.append(p_k)
                    r_k_list.append(r_k)
                
                query_precisions.append(p_k_list)
                query_recalls.append(r_k_list)

        if not query_precisions:
            continue

        # Calculate average P@k/R@k for each k
        max_k = max(len(p) for p in query_precisions)
        avg_precisions = []
        avg_recalls = []
        
        for i in range(max_k):
            p_vals = [q[i] for q in query_precisions if len(q) > i]
            r_vals = [q[i] for q in query_recalls if len(q) > i]
            if p_vals:
                avg_precisions.append(np.mean(p_vals))
                avg_recalls.append(np.mean(r_vals))

        pipeline_groups[group][model] = {
            "precisions": avg_precisions,
            "recalls": avg_recalls
        }
    
    # Plot Precision vs Recall curves grouped by pipeline
    for group_name, group_models in pipeline_groups.items():
        fig, ax = plt.subplots(figsize=(10, 8), layout='constrained')
        
        for model_name, metrics in sorted(group_models.items()):
            precisions = metrics["precisions"]
            recalls = metrics["recalls"]

            # Plot line connecting cutoff points (@1 to @10)
            ax.plot(recalls, precisions, marker='o', label=model_name, linewidth=2, markersize=5)
            
            # Annotate small cutoff index (@k) near each point
            #for k, (r, p) in enumerate(zip(recalls, precisions), 1):
                #ax.annotate(f"@{k}", (r, p), fontsize=8, xytext=(3, 3), textcoords='offset points', alpha=0.7)

        readable_title = group_name.replace("_","").replace("No", "No ").replace("Stop", "Stop ").replace("Removal", "Removal ").replace("Stemming", " Stemming ")
        
        ax.set_xlabel('Recall', fontsize=12, fontweight='bold')
        ax.set_ylabel('Precision', fontsize=12, fontweight='bold')
        ax.set_title(f"{readable_title.strip()} - Average Precision vs Recall Curves (Cutoffs @1 to @10)", fontsize=13, fontweight='bold', pad=12)
        
        ax.grid(True, linestyle='--', alpha=0.5, color='gray')
        ax.legend(title="Models", loc='best', frameon=True, fontsize=10)
        
        plt.savefig(PLOTS_DIR / f"precision_vs_recall_probabilistic_var_{group_name}.png", dpi=300, bbox_inches='tight')
        plt.close()


def plot_precision_recall_bubble_probabilistic():
    """
    Plots model metrics of all probabilistic model variants and groups using a bubble chart.
    """
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    PLOTS_DIR.mkdir(parents=True, exist_ok=True)

    files = list(Path(RESULTS_DIR).glob('**/metrics_**_aggregated.txt'))
    
    pipeline_groups = {}
    files_number = 0
    
    for file in files:
        group = file.name.split("_")[1]
        model = file.name.replace(group + "_", "").replace("metrics_", "").replace("_aggregated.txt", "")
        if model.split("_")[0] == "Probabilistic": 
            model = "Prob." + '(k=' + model.split("_")[1][1:] + ',b=' + model.split("_")[2][1:] + ')'
        if model.split("_")[0] == "Vectorial": 
            continue
        if group not in pipeline_groups: 
            pipeline_groups[group] = {}
        if model not in pipeline_groups[group]: 
            pipeline_groups[group][model] = {}
        else: 
            continue
        
        files_number += 1

        with file.open('r') as f:
            pipeline_groups[group][model]["Precision@10"] = float(str(f.readline()).split(" ")[-1])
            pipeline_groups[group][model]["Recall@10"] = float(str(f.readline()).split(" ")[-1])
            pipeline_groups[group][model]["MAP@10"] = float(str(f.readline()).split(" ")[-1])
    
    if not pipeline_groups:
        return

    files_by_group = int(files_number / len(pipeline_groups))
    
    fig, ax = plt.subplots(figsize=(12, 10), layout='constrained')

    all_labels = sorted(list(set(label for group in pipeline_groups.values() for label in group.keys())))
    label_to_num = {name: i + 1 for i, name in enumerate(all_labels)}

    for group_name, group in pipeline_groups.items():
        x_vals, y_vals, sizes, nums = [], [], [], []
        
        min_map = min(group[label]["MAP@10"] for label in group.keys() if "MAP@10" in group[label])
        for label, single_metrics in group.items():
            y_vals.append(single_metrics["Precision@10"])
            x_vals.append(single_metrics["Recall@10"])
            sizes.append((single_metrics["MAP@10"] - min_map + 0.1 * min_map) * 10000)
            nums.append(label_to_num[label])

        ax.scatter(x_vals, y_vals, s=sizes, alpha=0.6, edgecolors="k", linewidth=1.2, label=group_name)

        for x, y, num in zip(x_vals, y_vals, nums):
            ax.text(x, y, str(num), ha='center', va='center', fontsize=12, fontweight='bold', color='black')

    ax.set_ylabel('Precision@10', fontsize=11, fontweight='bold')
    ax.set_xlabel('Recall@10', fontsize=11, fontweight='bold')
    ax.set_title('All Groups - Average Precision vs Recall (Size = MAP@10)', fontsize=15, fontweight='bold', pad=12)
    ax.grid(True, linestyle='--', alpha=0.5, color='gray')

    group_legend = ax.legend(title="Groups", loc='upper left', fontsize=15, frameon=True)
    ax.add_artist(group_legend)

    num_handles = [ 
        plt.Line2D([0], [0], marker='o', color='w', label=f"{num}: {name}", 
                   markerfacecolor='gray', markersize=7, markeredgecolor='k') 
        for name, num in label_to_num.items()
    ]
    ax.legend(handles=num_handles, title="Models Index", loc='lower right', fontsize=15, ncols=2, frameon=True) 

    plt.savefig(PLOTS_DIR / "precision_vs_recall_probabilistic_var_all_groups_bubble.png", dpi=300, bbox_inches='tight')
    plt.close()


def plot_precision_recall_vectorial_vs_probabilistic():
    """
    Plots Precision vs Recall curves (cutoffs @1 to @10) combining all pipeline groups and models into a single chart.
    """
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    PLOTS_DIR.mkdir(parents=True, exist_ok=True)
    
    files = list(Path(RESULTS_DIR).glob('top_10_docs_*.txt'))
    all_curves = {}

    for file in files:
        filename = file.name.replace("top_10_docs_", "").replace(".txt", "")
        
        if "Probabilistic" in filename:
            if "_Probabilistic_k1.2_b1.0" in filename:
                group, model_part = filename.split("_Probabilistic_", 1)
                parts = model_part.split("_")
                k_val = parts[0]
                b_val = parts[1] if len(parts) > 1 else "b1.0"
                model = f"Probabilistic (k={k_val[1:]}, b={b_val[1:]})"
            else:
                continue
        elif "Vectorial" in filename:
            group = filename.split("_")[0]
            model = f"Vectorial ({filename.split('_')[1].replace('.txt', '')})"
        else: 
            continue

        query_precisions = []
        query_recalls = []

        with file.open('r') as f:
            for line in f:
                if ":" not in line:
                    continue
                try:
                    items = ast.literal_eval(line.split(":")[1].strip())
                except Exception:
                    continue
                
                if not items:
                    continue

                total_relevant = sum(1 for _, _, rel in items if rel == 1)
                p_k_list, r_k_list = [], []
                relevant_so_far = 0
                
                for k, (doc_id, score, rel) in enumerate(items, 1):
                    if rel == 1:
                        relevant_so_far += 1
                    
                    p_k = relevant_so_far / k
                    r_k = (relevant_so_far / total_relevant) if total_relevant > 0 else 0.0
                    
                    p_k_list.append(p_k)
                    r_k_list.append(r_k)
                
                query_precisions.append(p_k_list)
                query_recalls.append(r_k_list)

        if not query_precisions:
            continue

        max_k = max(len(p) for p in query_precisions)
        avg_precisions, avg_recalls = [], []
        
        for i in range(max_k):
            p_vals = [q[i] for q in query_precisions if len(q) > i]
            r_vals = [q[i] for q in query_recalls if len(q) > i]
            if p_vals:
                avg_precisions.append(np.mean(p_vals))
                avg_recalls.append(np.mean(r_vals))

        key = f"{group} - {model}"
        all_curves[key] = {
            "precisions": avg_precisions,
            "recalls": avg_recalls
        }
    
    if not all_curves:
        return

    fig, ax = plt.subplots(figsize=(12, 9), layout='constrained')
    
    cmap = mpl.colormaps['tab10']
    sorted_curves = sorted(all_curves.items())
    total_curves = len(sorted_curves)

    for idx, (label_name, metrics) in enumerate(sorted_curves):
        color = cmap(idx / max(total_curves - 1, 1)) if total_curves > 1 else cmap(0.0)
        marker = 'o' if "Vectorial" in label_name else 's'
        
        ax.plot(metrics["recalls"], metrics["precisions"], marker=marker, label=label_name, color=color, linewidth=2, markersize=5)
        
        #for k, (r, p) in enumerate(zip(metrics["recalls"], metrics["precisions"]), 1):
            #ax.annotate(f"@{k}", (r, p), fontsize=8, xytext=(3, 3), textcoords='offset points', alpha=0.6)

    ax.set_xlabel('Recall', fontsize=12, fontweight='bold')
    ax.set_ylabel('Precision', fontsize=12, fontweight='bold')
    ax.set_title("All Groups & Models - Precision vs Recall Curves (Cutoffs @1 to @10)", fontsize=13, fontweight='bold', pad=12)
    ax.grid(True, linestyle='--', alpha=0.5, color='gray')
    ax.legend(title="Groups & Models", loc='upper right', frameon=True, fontsize=9, title_fontsize=10)
    
    plt.savefig(PLOTS_DIR / "precision_vs_recall_all_groups_combined.png", dpi=300, bbox_inches='tight')
    plt.close()


def plot_metrics_vectorial_vs_probabilistic():
    """
    Parses evaluation files containing metrics, aggregates all groups and models,
    and generates a sorted horizontal bar chart (descending) for each metric.
    """
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    PLOTS_DIR.mkdir(parents=True, exist_ok=True)
    
    files = list(Path(RESULTS_DIR).glob('metrics*.txt'))
    all_metrics_data = {}

    for file in files:
        filename = file.name.replace("metrics_", "").replace(".txt", "")
        
        if "Probabilistic" in filename:
            if "_Probabilistic_k1.2_b1.0" in filename:
                parts_split = filename.split("_Probabilistic_")
                group = parts_split[0]
                model_part = parts_split[1]
                parts = model_part.split("_")
                k_val = parts[0]
                b_val = parts[1] if len(parts) > 1 else "b1.0"
                model = f"Probabilistic (k={k_val[1:]}, b={b_val[1:]})"
            else:
                continue
        elif "Vectorial" in filename:
            parts = filename.split("_")
            group = parts[0]
            model = f"Vectorial ({parts[1]})"
        else: 
            continue
        
        group = group.replace("NoStopRemoval","").replace("NoStemming", "").replace("With", "", 1).replace("With"," and ").replace("StopRemoval", "Stop Removal")
        if group == "": 
            group = "Nothing"
        label = f"{group} - {model}"

        try:
            content = file.read_text()
        except Exception:
            continue

        matches = re.findall(r'([\w@]+)\s*:\s*([0-9]+\.[0-9]+)', content)
        
        if not matches:
            for line in content.splitlines():
                if ":" in line:
                    parts = line.split(":")
                    if len(parts) == 2:
                        m_key = parts[0].strip()
                        try:
                            m_val = float(parts[1].strip())
                            if m_key not in all_metrics_data:
                                all_metrics_data[m_key] = {}
                            all_metrics_data[m_key][label] = m_val
                        except ValueError:
                            continue
        else:
            for m_key, m_val_str in matches:
                try:
                    m_val = float(m_val_str)
                    if m_key not in all_metrics_data:
                        all_metrics_data[m_key] = {}
                    all_metrics_data[m_key][label] = m_val
                except ValueError:
                    continue

    for metric_name, model_values in all_metrics_data.items():
        if not model_values:
            continue

        sorted_items = sorted(model_values.items(), key=lambda x: x[1], reverse=True)
        labels = [item[0] for item in sorted_items]
        values = [item[1] for item in sorted_items]

        fig, ax = plt.subplots(figsize=(10, max(5, len(labels) * 0.45)), layout='constrained')
        bars = ax.barh(labels, values, color='cornflowerblue', edgecolor='black', alpha=0.85)
        
        ax.invert_yaxis()
        max_val = max(values) if values else 1.0
        ax.set_xlim(0, max_val * 1.20)
        
        ax.set_xlabel(metric_name.upper(), fontsize=10, fontweight='bold')
        ax.set_title(f"Comparison of Average {metric_name.upper()} Across All Groups", fontsize=13, fontweight='bold', pad=12)
        ax.grid(True, axis='x', linestyle='--', alpha=0.5, color='gray')

        for bar in bars:
            width = bar.get_width()
            ax.text(width + 0.005, bar.get_y() + bar.get_height()/2, f"{width:.4f}", 
                    va='center', ha='left', fontsize=9, fontweight='bold', alpha=0.8)

        plt.savefig(PLOTS_DIR / f"probabilistic_vs_vectorial_{metric_name}.png", dpi=300, bbox_inches='tight')
        plt.close()


def plot_metrics_probabilistic_all_var():
    """
    Parses evaluation files containing metrics, aggregates all probabilistic models and groups,
    and generates a sorted horizontal bar chart (descending) for each metric.
    """
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    PLOTS_DIR.mkdir(parents=True, exist_ok=True)
    
    files = list(Path(RESULTS_DIR).glob('metrics*.txt'))
    all_metrics_data = {}

    for file in files:
        filename = file.name.replace("metrics_", "").replace(".txt", "")
        
        if "Probabilistic" in filename:
            parts_split = filename.split("_Probabilistic_")
            group = parts_split[0]
            model_part = parts_split[1]
            parts = model_part.split("_")
            k_val = parts[0]
            b_val = parts[1] if len(parts) > 1 else "b1.0"
            model = f"Probabilistic (k={k_val[1:]}, b={b_val[1:]})"
        else: 
            continue
        
        group = group.replace("NoStopRemoval","").replace("NoStemming", "").replace("With", "", 1).replace("With"," and ")
        if group == "": 
            group = "Nothing"
        label = f"{group} - {model}"

        try:
            content = file.read_text()
        except Exception:
            continue

        matches = re.findall(r'([\w@]+)\s*:\s*([0-9]+\.[0-9]+)', content)
        
        if not matches:
            for line in content.splitlines():
                if ":" in line:
                    parts = line.split(":")
                    if len(parts) == 2:
                        m_key = parts[0].strip()
                        try:
                            m_val = float(parts[1].strip())
                            if m_key not in all_metrics_data:
                                all_metrics_data[m_key] = {}
                            all_metrics_data[m_key][label] = m_val
                        except ValueError:
                            continue
        else:
            for m_key, m_val_str in matches:
                try:
                    m_val = float(m_val_str)
                    if m_key not in all_metrics_data:
                        all_metrics_data[m_key] = {}
                    all_metrics_data[m_key][label] = m_val
                except ValueError:
                    continue

    for metric_name, model_values in all_metrics_data.items():
        if not model_values:
            continue

        sorted_items = sorted(model_values.items(), key=lambda x: x[1], reverse=True)
        labels = [item[0] for item in sorted_items]
        values = [item[1] for item in sorted_items]

        fig, ax = plt.subplots(figsize=(3, max(5, len(labels) * 0.45)), layout='constrained')
        bars = ax.barh(labels, values, color='cornflowerblue', edgecolor='black', alpha=0.85)
        
        ax.invert_yaxis()
        max_val = max(values) if values else 1.0
        ax.set_xlim(0, max_val * 1.50)
        
        ax.set_xlabel(metric_name.upper(), fontsize=10, fontweight='bold')
        ax.set_title(f"Comparison of Average {metric_name.upper()} Across All Groups", fontsize=13, fontweight='bold', pad=12)
        ax.grid(True, axis='x', linestyle='--', alpha=0.5, color='gray')

        for bar in bars:
            width = bar.get_width()
            ax.text(width + 0.005, bar.get_y() + bar.get_height()/2, f"{width:.4f}", 
                    va='center', ha='left', fontsize=9, fontweight='bold', alpha=0.8)

        plt.savefig(PLOTS_DIR / f"probabilistic_var_{metric_name}.png", dpi=300, bbox_inches='tight')
        plt.close()


def plot_metrics_probabilistic_subplots():
    """
    Parses evaluation files containing metrics, groups them by pipeline group,
    and generates a single image with subplots (one sorted horizontal bar chart per metric).
    """
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    PLOTS_DIR.mkdir(parents=True, exist_ok=True)
    
    files = list(Path(RESULTS_DIR).glob('metrics*.txt'))
    grouped_metrics_data = {}

    for file in files:
        filename = file.name.replace("metrics_", "").replace(".txt", "")
        
        if "Probabilistic" in filename:
            parts_split = filename.split("_Probabilistic_")
            raw_group = parts_split[0]
            model_part = parts_split[1]
            parts = model_part.split("_")
            k_val = parts[0]
            b_val = parts[1] if len(parts) > 1 else "b1.0"
            model = f"Prob. (k={k_val[1:]}, b={b_val[1:]})"
        else: 
            continue
        
        group = raw_group.replace("NoStopRemoval","").replace("NoStemming", "").replace("With", "", 1).replace("With"," and ")
        if group == "": 
            group = "Nothing"

        try:
            content = file.read_text()
        except Exception:
            continue

        matches = re.findall(r'([\w@]+)\s*:\s*([0-9]+\.[0-9]+)', content)
        parsed_metrics = []
        
        if not matches:
            for line in content.splitlines():
                if ":" in line:
                    parts = line.split(":")
                    if len(parts) == 2:
                        m_key = parts[0].strip()
                        try:
                            parsed_metrics.append((m_key, float(parts[1].strip())))
                        except ValueError:
                            continue
        else:
            for m_key, m_val_str in matches:
                try:
                    parsed_metrics.append((m_key, float(m_val_str)))
                except ValueError:
                    continue

        for m_key, m_val in parsed_metrics:
            if group not in grouped_metrics_data:
                grouped_metrics_data[group] = {}
            if m_key not in grouped_metrics_data[group]:
                grouped_metrics_data[group][m_key] = {}
            grouped_metrics_data[group][m_key][model] = m_val

    for group_name, metrics_dict in grouped_metrics_data.items():
        metrics_list = list(metrics_dict.items())
        num_metrics = len(metrics_list)
        
        if num_metrics == 0:
            continue

        fig, axes = plt.subplots(num_metrics, 1, figsize=(12, 4 * num_metrics), layout='constrained')
        
        if num_metrics == 1:
            axes = [axes]

        for ax, (metric_name, model_values) in zip(axes, metrics_list):
            if not model_values:
                continue

            sorted_items = sorted(model_values.items(), key=lambda x: x[1], reverse=True)
            labels = [item[0] for item in sorted_items]
            values = [item[1] for item in sorted_items]

            bars = ax.barh(labels, values, color='cornflowerblue', edgecolor='black', alpha=0.85)
            ax.invert_yaxis()

            max_val = max(values) if values else 1.0
            ax.set_xlim(0, max_val * 1.25)
            
            ax.set_xlabel(metric_name.upper(), fontsize=10, fontweight='bold')
            ax.set_title(f"{metric_name.upper()} (Sorted)", fontsize=11, fontweight='bold', pad=8)
            ax.grid(True, axis='x', linestyle='--', alpha=0.5, color='gray')

            for bar in bars:
                width = bar.get_width()
                ax.text(width + (max_val * 0.01), bar.get_y() + bar.get_height()/2, f"{width:.4f}", 
                        va='center', ha='left', fontsize=9, fontweight='bold', alpha=0.8)

        fig.suptitle(f"{group_name} - Metrics Comparison", fontsize=14, fontweight='bold', y=1.02)

        safe_group_name = group_name.replace(" ", "_").lower()
        plt.savefig(PLOTS_DIR / f"metrics_probabilistic_var_{safe_group_name}.png", dpi=300, bbox_inches='tight')
        plt.close()

def plot_metrics_probabilistic_all_groups_aggregated():
    """
    Parses evaluation files containing metrics, aggregates all groups and models together,
    and generates a single sorted horizontal bar chart (descending) for each metric.
    """
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    PLOTS_DIR.mkdir(parents=True, exist_ok=True)
    
    files = list(Path(RESULTS_DIR).glob('metrics*.txt'))
    
    # Store data as: metric_name -> { "Group - Model": value }
    all_metrics_aggregated = {}

    for file in files:
        filename = file.name.replace("metrics_", "").replace(".txt", "")
        
        if "Probabilistic" in filename:
            parts_split = filename.split("_Probabilistic_")
            raw_group = parts_split[0]
            model_part = parts_split[1]
            parts = model_part.split("_")
            k_val = parts[0]
            b_val = parts[1] if len(parts) > 1 else "b1.0"
            model = f"Prob. (k={k_val[1:]}, b={b_val[1:]})"
        else: 
            continue
        
        # Clean up group name for display
        group = raw_group.replace("NoStopRemoval","").replace("NoStemming", "").replace("With", "", 1).replace("With"," and ")
        if group == "": 
            group = "Nothing"

        try:
            content = file.read_text()
        except Exception:
            continue

        matches = re.findall(r'([\w@]+)\s*:\s*([0-9]+\.[0-9]+)', content)
        parsed_metrics = []
        
        if not matches:
            for line in content.splitlines():
                if ":" in line:
                    parts = line.split(":")
                    if len(parts) == 2:
                        m_key = parts[0].strip()
                        try:
                            parsed_metrics.append((m_key, float(parts[1].strip())))
                        except ValueError:
                            continue
        else:
            for m_key, m_val_str in matches:
                try:
                    parsed_metrics.append((m_key, float(m_val_str)))
                except ValueError:
                    continue

        # Create a unique combined label for each group + model variant
        label = f"{group} - {model}"

        for m_key, m_val in parsed_metrics:
            if m_key not in all_metrics_aggregated:
                all_metrics_aggregated[m_key] = {}
            all_metrics_aggregated[m_key][label] = m_val

    # Generate a sorted horizontal bar chart for each metric combining all groups
    for metric_name, model_values in all_metrics_aggregated.items():
        if not model_values:
            continue

        # Sort from greatest to least (descending order) across all groups & models
        sorted_items = sorted(model_values.items(), key=lambda x: x[1], reverse=True)
        labels = [item[0] for item in sorted_items]
        values = [item[1] for item in sorted_items]

        fig, ax = plt.subplots(figsize=(12, max(6, len(labels) * 0.35)), layout='constrained')
        
        bars = ax.barh(labels, values, color='cornflowerblue', edgecolor='black', alpha=0.85)
        
        # Invert y-axis so the highest value appears at the top
        ax.invert_yaxis()

        max_val = max(values) if values else 1.0
        ax.set_xlim(0, max_val * 1.25)
        
        ax.set_xlabel(metric_name.upper(), fontsize=10, fontweight='bold')
        ax.set_title(f"All Groups Comparison - {metric_name.upper()} (Sorted)", fontsize=13, fontweight='bold', pad=12)
        ax.grid(True, axis='x', linestyle='--', alpha=0.5, color='gray')

        # Annotate numerical values directly on the bars
        for bar in bars:
            width = bar.get_width()
            ax.text(width + (max_val * 0.01), bar.get_y() + bar.get_height()/2, f"{width:.4f}", 
                    va='center', ha='left', fontsize=9, fontweight='bold', alpha=0.8)

        # Save figure
        safe_metric_name = metric_name.replace("@", "_at_").lower()
        plt.savefig(PLOTS_DIR / f"metrics_probabilistic_all_groups_{safe_metric_name}.png", dpi=300, bbox_inches='tight')
        plt.close()

def plot_metrics_probabilistic_by_kb():
    """
    Parses evaluation files containing metrics, groups them by unique (k, b) parameters,
    and generates a separate sorted horizontal bar chart comparing pipeline groups for each configuration.
    """
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    PLOTS_DIR.mkdir(parents=True, exist_ok=True)
    
    files = list(Path(RESULTS_DIR).glob('metrics*.txt'))
    
    # Store data as: (k_val, b_val) -> metric_name -> {group_name: value}
    kb_metrics_data = {}

    for file in files:
        filename = file.name.replace("metrics_", "").replace(".txt", "")
        
        if "Probabilistic" in filename:
            parts_split = filename.split("_Probabilistic_")
            raw_group = parts_split[0]
            model_part = parts_split[1]
            parts = model_part.split("_")
            k_val = parts[0]
            b_val = parts[1] if len(parts) > 1 else "b1.0"
        else: 
            continue
        
        # Clean up group name for display
        group = raw_group.replace("NoStopRemoval","").replace("NoStemming", "").replace("With", "", 1).replace("With"," and ")
        if group == "": 
            group = "Nothing"

        try:
            content = file.read_text()
        except Exception:
            continue

        matches = re.findall(r'([\w@]+)\s*:\s*([0-9]+\.[0-9]+)', content)
        parsed_metrics = []
        
        if not matches:
            for line in content.splitlines():
                if ":" in line:
                    parts_line = line.split(":")
                    if len(parts_line) == 2:
                        m_key = parts_line[0].strip()
                        try:
                            parsed_metrics.append((m_key, float(parts_line[1].strip())))
                        except ValueError:
                            continue
        else:
            for m_key, m_val_str in matches:
                try:
                    parsed_metrics.append((m_key, float(m_val_str)))
                except ValueError:
                    continue

        kb_key = (k_val, b_val)
        for m_key, m_val in parsed_metrics:
            if kb_key not in kb_metrics_data:
                kb_metrics_data[kb_key] = {}
            if m_key not in kb_metrics_data[kb_key]:
                kb_metrics_data[kb_key][m_key] = {}
            kb_metrics_data[kb_key][m_key][group] = m_val

    # Generate separate sorted charts for each (k, b) and metric combination
    for (k_val, b_val), metrics_dict in kb_metrics_data.items():
        for metric_name, group_values in metrics_dict.items():
            if not group_values:
                continue

            # Sort from greatest to least (descending order)
            sorted_items = sorted(group_values.items(), key=lambda x: x[1], reverse=True)
            labels = [item[0] for item in sorted_items]
            values = [item[1] for item in sorted_items]

            fig, ax = plt.subplots(figsize=(10, max(4, len(labels) * 0.45)), layout='constrained')
            
            bars = ax.barh(labels, values, color='cornflowerblue', edgecolor='black', alpha=0.85)
            ax.invert_yaxis()

            max_val = max(values) if values else 1.0
            ax.set_xlim(0, max_val * 1.25)
            
            clean_k = k_val[1:]
            clean_b = b_val[1:]
            ax.set_xlabel(metric_name.upper(), fontsize=10, fontweight='bold')
            ax.set_title(f"Groups Comparison ({metric_name.upper()}) - BIM25 k={clean_k}, b={clean_b}", fontsize=12, fontweight='bold', pad=10)
            ax.grid(True, axis='x', linestyle='--', alpha=0.5, color='gray')

            for bar in bars:
                width = bar.get_width()
                ax.text(width + (max_val * 0.01), bar.get_y() + bar.get_height()/2, f"{width:.4f}", 
                        va='center', ha='left', fontsize=9, fontweight='bold', alpha=0.8)

            safe_metric = metric_name.replace("@", "_at_").lower()
            filename_out = f"metrics_probabilistic_k{clean_k}_b{clean_b}_{safe_metric}.png"
            plt.savefig(PLOTS_DIR / filename_out, dpi=300, bbox_inches='tight')
            plt.close()

