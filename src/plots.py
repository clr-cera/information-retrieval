import matplotlib.pyplot as plt
import numpy as np

from pathlib import Path
RESULTS_DIR = Path("result")
PLOTS_DIR = Path("plots")

def plot_models_avg_metrics():
    """
    Plots model metrics bars grouped by models.
    """
    # Make dir
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    PLOTS_DIR.mkdir(parents=True, exist_ok=True)

    # Select aggregated metrics files and extract data
    files = list(Path(RESULTS_DIR).glob('**/metrics_**_aggregated.txt'))
    
    pipeline_groups = {}
    files_number = 0
    for file in files:
        files_number += 1
        group = file.name.split("_")[1]
        model = file.name.replace(group + "_", "").replace("metrics_", "").replace("_aggregated.txt", "")
        if model.split("_")[0] == "Probabilistic": model = "Prob." + '(k=' + model.split("_")[1][1:] + ',b=' + model.split("_")[2][1:] + ')'
        if group not in pipeline_groups: pipeline_groups[group] = {}
        if model not in pipeline_groups[group]: pipeline_groups[group][model] = {}
        else: continue

        with file.open('r') as f:
            pipeline_groups[group][model]["Precision@10"] = (float(str(f.readline()).split(" ")[-1]))
            pipeline_groups[group][model]["Recall@10"] = (float(str(f.readline()).split(" ")[-1]))
            pipeline_groups[group][model]["MAP@10"] = (float(str(f.readline()).split(" ")[-1]))
    
    files_by_group = int(files_number/len(pipeline_groups))
    metrics = {
        "Precision@10": np.zeros(files_by_group),
        "Recall@10": np.zeros(files_by_group),
        "MAP@10": np.zeros(files_by_group)
    }
    
    # Assemble one chart by group -> BAR CHARTS
    for group_name, group in pipeline_groups.items():
        # Dynamically scale height based on number of models
        fig_height = max(6, len(group) * 0.4)
        fig, ax = plt.subplots(figsize=(7, fig_height), layout='constrained')
        
        labels = []
        for idx, (label, single_metrics) in enumerate(sorted(group.items())):
            labels.append(label)
            for metric, value in single_metrics.items():
                metrics[metric][idx] = value

        res = ax.grouped_bar(metrics, tick_labels=labels, group_spacing=0.8, orientation="horizontal")

        for container in res.bar_containers:
            ax.bar_label(container, padding=5, fmt='%.2f', fontsize=9)

        # Chart info
        readable_title = group_name.replace("No", "No ").replace("Removal", " Removal ").replace("Stemming", "Stemming ").replace("With", "With ")
        
        ax.set_xlabel('Score / Percentage', fontsize=11, fontweight='bold')
        ax.set_title(readable_title.strip(), fontsize=13, fontweight='bold', pad=12)
        ax.legend(loc='upper right', frameon=True, facecolor='white', edgecolor='none')
        
        # Add subtle background grid lines
        ax.xaxis.grid(True, linestyle='--', alpha=0.5, color='gray')
        ax.set_axisbelow(True)
        
        # Give a little extra headroom on the x-axis
        lim = 0
        for metric in metrics.values():
            lim = max(lim, max(metric))
        lim += round(lim/4,2) # Spacing

        ax.set_xlim(0, lim)
        
        plt.savefig(PLOTS_DIR / f"{group_name}_aggregated.png", dpi=300, bbox_inches='tight')
        plt.close()

    # Assemble one chart by group -> BUBBLE CHARTS
    for group_name, group in pipeline_groups.items():
        fig, ax = plt.subplots(figsize=(9, 7), layout='constrained')
        
        x_vals, y_vals, sizes, labels = [], [], [], []
        
        for label, single_metrics in sorted(group.items()):
            x_vals.append(single_metrics["Precision@10"])
            y_vals.append(single_metrics["Recall@10"])
            # Multiply MAP by a factor (e.g., 600) so the bubble sizes are clearly visible
            sizes.append(single_metrics["MAP@10"] * 600)
            labels.append(label)

        # Scatter plot (bubble chart)
        scatter = ax.scatter(x_vals, y_vals, s=sizes, alpha=0.6, edgecolors="k", linewidth=1.2)

        # Add model name labels next to each point
        for i, txt in enumerate(labels):
            ax.annotate(txt, (x_vals[i], y_vals[i]), fontsize=9, xytext=(6, 6), textcoords='offset points')

        readable_title = group_name.replace("No", "No ").replace("Removal", " Removal ").replace("Stemming", " Stemming")
        
        ax.set_xlabel('Precision@10', fontsize=11, fontweight='bold')
        ax.set_ylabel('Recall@10', fontsize=11, fontweight='bold')
        ax.set_title(f"{readable_title.strip()} - Precision vs Recall (Size = MAP@10)", fontsize=12, fontweight='bold', pad=12)
        
        ax.grid(True, linestyle='--', alpha=0.5, color='gray')
        
        plt.savefig(PLOTS_DIR / f"{group_name}_scatter.png", dpi=300, bbox_inches='tight')
        plt.close()

    # ALL IN ONE BUBBLE CHART
    fig, ax = plt.subplots(figsize=(12, 10), layout='constrained')

    # 1. Assign a unique, consistent number to every unique model name across all groups
    all_labels = sorted(list(set(label for group in pipeline_groups.values() for label in group.keys())))
    label_to_num = {name: i + 1 for i, name in enumerate(all_labels)}

    # 2. Plot each group
    for group_name, group in pipeline_groups.items():
        x_vals, y_vals, sizes, nums = [], [], [], []
        
        for label, single_metrics in group.items():
            x_vals.append(single_metrics["Precision@10"])
            y_vals.append(single_metrics["Recall@10"])
            sizes.append(single_metrics["MAP@10"] * 3000)  # Adjust scale if needed
            nums.append(label_to_num[label])

        # Scatter plot for the group
        ax.scatter(x_vals, y_vals, s=sizes, alpha=0.6, edgecolors="k", linewidth=1.2, label=group_name)

        # Put numbers directly inside the bubbles
        for x, y, num in zip(x_vals, y_vals, nums):
            ax.text(x, y, str(num), ha='center', va='center', fontsize=12, fontweight='bold', color='black')

    ax.set_xlabel('Precision@10', fontsize=11, fontweight='bold')
    ax.set_ylabel('Recall@10', fontsize=11, fontweight='bold')
    ax.set_title('All Groups - Precision vs Recall (Size = MAP@10)', fontsize=15, fontweight='bold', pad=12)

    ax.grid(True, linestyle='--', alpha=0.5, color='gray')

    # 3. Add Group Legend
    group_legend = ax.legend(title="Groups", loc='upper left', fontsize=15, frameon=True)
    ax.add_artist(group_legend)

    # 4. Add Model Index Legend (meaning of each number)
    num_handles = [
        plt.Line2D([0], [0], marker='o', color='w', label=f"{num}: {name}", 
                   markerfacecolor='gray', markersize=7, markeredgecolor='k') 
        for name, num in label_to_num.items()
    ]
    ax.legend(handles=num_handles, title="Models Index", loc='lower right', fontsize=15, ncols=2, frameon=True) 

    plt.savefig(PLOTS_DIR / "all_groups_numbered_scatter.png", dpi=300, bbox_inches='tight')

plot_models_avg_metrics()
