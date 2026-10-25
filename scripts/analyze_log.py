"""Analyze the query log and plot per-query execution times.

The chart is drawn inside a fixed-size viewport: the number of visible rows,
the distance between two consecutive rows and the bar thickness stay constant
no matter how many queries the log contains. With ~60 queries the bars used to
be squeezed into a few pixels each; now the viewport shows a readable window
and a scrollbar (plus the mouse wheel and PageUp/PageDown) moves it over the
whole list.

Both charts share the same row ordering (one row per query, sorted by name), so
a single scroll position makes sense for the two panels. The left panel shows
the latest day, where a query that was not executed on that day simply has no
bar (it still keeps its row, so the rows stay aligned with the right panel).
"""

import os
import sys

import matplotlib.pyplot as plt
from matplotlib.widgets import Slider
from pandas import read_csv, errors

# Path to the log file
LOG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "LogFile", "query_log.csv")

# Viewport settings. The number of visible rows is derived from the screen so
# the window always fits on screen, while the row pitch and the bar thickness
# stay constant no matter how many queries the log contains.
ROW_PITCH_INCH = 0.34      # vertical space per row, in inches
DPI = 100                  # render resolution used for the on-screen window
MIN_VISIBLE_ROWS = 8
MAX_VISIBLE_ROWS = 30
CHROME_INCH = 2.6          # title + axes labels + slider overhead, in inches
MIN_FIG_WIDTH_INCH = 12.0
MAX_FIG_WIDTH_INCH = 15.0


def _screen_size():
    """Return the primary screen size in pixels, with sane fallbacks."""
    try:
        import tkinter

        root = tkinter.Tk()
        root.withdraw()
        w, h = root.winfo_screenwidth(), root.winfo_screenheight()
        root.destroy()
        if w > 200 and h > 200:
            return w, h
    except Exception:
        pass
    return 1600, 900


def viewport_layout():
    """Compute (visible_rows, fig_width_inch, fig_height_inch) for this screen."""
    screen_w, screen_h = _screen_size()

    # Leave room for the window frame and the taskbar
    usable_h = min(screen_h * 0.82, 1000)
    fig_h = usable_h / DPI

    rows = int((fig_h - CHROME_INCH) / ROW_PITCH_INCH)
    rows = max(MIN_VISIBLE_ROWS, min(MAX_VISIBLE_ROWS, rows))

    fig_w = min(max(screen_w * 0.95 / DPI, MIN_FIG_WIDTH_INCH), MAX_FIG_WIDTH_INCH)
    return rows, fig_w, fig_h


def load_log(log_file=LOG_FILE):
    """Read the log file and return a DataFrame with a `date` column."""
    if not os.path.exists(log_file):
        print("Log file not found:", log_file)
        sys.exit(1)

    try:
        df = read_csv(log_file, encoding="utf-8", parse_dates=["datetime"])
    except errors.ParserError as e:
        raise ValueError(
            f"Failed to parse log file '{log_file}'. It may be corrupted or incorrectly formatted."
        ) from e
    except Exception as e:
        raise RuntimeError(f"Failed to read log file '{log_file}'") from e

    if df.empty:
        print("Log file is empty.")
        sys.exit(0)

    df["date"] = df["datetime"].dt.date
    return df


def build_series(df):
    """Return (labels, latest_values, max_values, latest_date).

    Rows are ordered by query name and numbered once, so the left (latest day)
    and right (all-time max) panels share the same row positions.
    """
    latest_date = df["date"].max()
    df_latest = df[df["date"] == latest_date]

    # Max elapsed time per SQL across the whole log
    df_max_all = df.groupby("sql_file", as_index=False)["elapsed_sec"].max()

    # Max elapsed time per SQL on the latest day
    df_latest_grouped = df_latest.groupby("sql_file", as_index=False)["elapsed_sec"].max()

    labels = sorted(df_max_all["sql_file"].tolist())
    numbers = {name: f"{i + 1}._{name}" for i, name in enumerate(labels)}

    all_map = dict(zip(df_max_all["sql_file"], df_max_all["elapsed_sec"]))
    latest_map = dict(zip(df_latest_grouped["sql_file"], df_latest_grouped["elapsed_sec"]))

    max_values = [float(all_map[name]) for name in labels]
    # Missing on the latest day -> NaN: the row is kept but no bar is drawn
    latest_values = [float(latest_map[name]) if name in latest_map else float("nan") for name in labels]
    row_labels = [numbers[name] for name in labels]

    return row_labels, latest_values, max_values, latest_date


def plot_scrollable_chart(df):
    """Draw the two-panel chart inside a fixed-size scrollable viewport."""
    row_labels, latest_values, max_values, latest_date = build_series(df)

    total = len(row_labels)
    rows_per_view, fig_w, fig_h = viewport_layout()
    visible = min(rows_per_view, total) if total else 1

    # The figure height depends only on the number of VISIBLE rows, never on the
    # total number of queries -> constant row pitch and bar thickness.
    fig, axes = plt.subplots(nrows=1, ncols=2, sharey=False, figsize=(fig_w, fig_h), dpi=DPI)
    fig.canvas.manager.set_window_title("SQL Query Log Analysis")

    positions = list(range(total))

    # ---- Left panel: latest day ----
    bars_latest = axes[0].barh(
        positions, latest_values, height=0.72, color="skyblue", edgecolor="#4a90a4", linewidth=0.6
    )
    axes[0].set_title(f"{latest_date} (latest day)")
    axes[0].set_xlabel("Elapsed time (s)")

    # ---- Right panel: all-time max ----
    bars_max = axes[1].barh(
        positions, max_values, height=0.72, color="#e05c5c", edgecolor="#a83c3c", linewidth=0.6
    )
    axes[1].set_title("Max query time (all log)")
    axes[1].set_xlabel("Elapsed time (s)")

    # Row labels: only the left panel carries them - both panels share the same
    # row positions, so a single label column is enough and it cannot collide
    # with the other panel.
    for i, ax in enumerate(axes):
        ax.set_yticks(positions)
        ax.grid(axis="x", linestyle=":", alpha=0.45, zorder=0)
        ax.set_axisbelow(True)
        ax.tick_params(axis="y", length=0, pad=4)

        # Light zebra bands so a row can be followed across both panels
        for pos in positions:
            if pos % 2 == 1:
                ax.axhspan(pos - 0.5, pos + 0.5, color="#000000", alpha=0.045, zorder=0)

    axes[0].set_yticklabels(row_labels, fontsize=8)
    axes[1].tick_params(axis="y", labelleft=False)

    # Value labels at the end of every bar (empty for rows without data)
    def _label(ax, bars, values):
        texts = ax.bar_label(
            bars,
            labels=[f"{v:.1f}" if v == v else "" for v in values],  # NaN -> no text
            label_type="edge",
            padding=3,
            fontsize=7,
        )
        # Clip so labels scrolled out of the viewport do not spill over the axes
        for t in texts:
            t.set_clip_on(True)
            t.set_clip_path(ax.patch)

    _label(axes[0], bars_latest, latest_values)
    _label(axes[1], bars_max, max_values)

    # Leave room on the right for value labels
    for ax, values in ((axes[0], latest_values), (axes[1], max_values)):
        finite = [v for v in values if v == v]
        top = max(finite) if finite else 1.0
        ax.set_xlim(0, top * 1.18 if top > 0 else 1.0)

    # ---- Scrollbar ----
    max_start = max(0, total - visible)
    if max_start <= 0:
        # Everything fits: no scrollbar at all (avoids a degenerate slider range)
        fig.suptitle(f"Queries 1-{total} of {total} - all rows fit, no scrolling needed", fontsize=9)

        class _NullSlider:
            val = 0
            valmax = 0
            valmin = 0

            def set_val(self, _v):
                pass

            def set_active(self, _v):
                pass

        fig.subplots_adjust(left=0.22, right=0.965, top=0.90, bottom=0.08, wspace=0.30)
        for ax in axes:
            ax.set_ylim(total - 0.5, -0.5)
        return fig, axes, _NullSlider()

    slider_ax = fig.add_axes([0.08, 0.035, 0.86, 0.028])
    slider = Slider(
        slider_ax,
        "Scroll",
        valmin=0,
        valmax=max_start,
        valinit=0,
        valstep=1,
        color="#7aa9c9",
        initcolor="none",
    )
    slider.label.set_fontsize(8)
    slider.valtext.set_fontsize(8)
    slider.poly.set_visible(True)

    def apply_view(start, sync_slider=True):
        start = int(max(0, min(start, max_start)))
        bottom = start + visible - 0.5
        top = start - 0.5
        for ax in axes:
            ax.set_ylim(bottom, top)
        if total > visible:
            fig.suptitle(
                f"Queries {start + 1}-{start + visible} of {total}   "
                f"(scrollbar, mouse wheel or PageUp/PageDown to browse)",
                fontsize=9,
            )
        else:
            fig.suptitle(f"Queries 1-{total} of {total}", fontsize=9)
        # Move the scrollbar handle too, avoiding the on_changed -> apply_view loop
        if sync_slider and slider.val != start:
            slider.eventson = False
            slider.set_val(start)
            slider.eventson = True
        fig.canvas.draw_idle()

    def on_slider(val):
        apply_view(int(val))

    slider.on_changed(on_slider)

    # Mouse wheel scrolling over the figure
    def on_scroll(event):
        if max_start <= 0:
            return
        step = 1 if getattr(event, "step", 1) > 0 else -1
        if event.button == "up":
            step = 1
        elif event.button == "down":
            step = -1
        elif event.button not in ("up", "down"):
            step = int(getattr(event, "step", 1))
        current = int(round(slider.val))
        target = max(0, min(current - step * 3, max_start))
        if target != current:
            slider.set_val(target)

    fig.canvas.mpl_connect("scroll_event", on_scroll)

    # PageUp / PageDown / Home / End keys
    def on_key(event):
        if max_start <= 0:
            return
        current = int(round(slider.val))
        step = visible
        if event.key == "pageup":
            target = current - step
        elif event.key == "pagedown":
            target = current + step
        elif event.key == "home":
            target = 0
        elif event.key == "end":
            target = max_start
        else:
            return
        slider.set_val(max(0, min(target, max_start)))

    fig.canvas.mpl_connect("key_press_event", on_key)

    fig.subplots_adjust(left=0.22, right=0.965, top=0.90, bottom=0.12, wspace=0.30)
    apply_view(0)

    # Keep a reference so the slider is not garbage collected
    fig._scroll_slider = slider
    fig._apply_view = apply_view
    return fig, axes, slider


def main():
    df = load_log()
    fig, _axes, _slider = plot_scrollable_chart(df)
    plt.show()


if __name__ == "__main__":
    main()
