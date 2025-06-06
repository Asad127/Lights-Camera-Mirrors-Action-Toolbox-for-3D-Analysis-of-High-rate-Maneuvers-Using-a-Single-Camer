import json
from pathlib import Path
from typing import Literal

import cv2
import numpy as np

# Configuration
BASEDIR = "depth-anything-v2"
IMAGE_DIR = Path(BASEDIR, "color")
OUTPUT_FILE = Path(BASEDIR, "annotated_coordinates.json")
SUPPORTED_EXTENSIONS = (".png", ".jpg", ".jpeg", ".bmp", ".tiff", ".webp")
MAX_DISPLAY_WIDTH = 1280
MAX_DISPLAY_HEIGHT = 720
POINT_RADIUS = 5
# Colors in BGR order
POINT_COLOR = (0, 0, 255)
TEXT_COLOR = (0, 255, 0)
MIN_USER_ZOOM = 0.5
MAX_USER_ZOOM = 20
ZOOM_CHANGE_FACTOR = 1.1

# Global state variables
current_points = []
original_image = None
precomputed_image = None
g_orig_image_height = 0
g_orig_image_width = 0
g_display_window_name = "Image Annotator (Zoom/Pan)"
g_display_window_height = 0
g_display_window_width = 0
g_base_scale_factor = 1.0
g_user_zoom_level = 1.0
g_view_center_orig_x = 0.0
g_view_center_orig_y = 0.0
g_is_panning = False
g_pan_start_mouse_x = 0
g_pan_start_mouse_y = 0
g_pan_start_view_center_x = 0
g_pan_start_view_center_y = 0


def reset_zoom_pan_state():
    """Resets zoom and pan to initial fit for the current original_image."""
    global g_user_zoom_level, g_view_center_orig_x, g_view_center_orig_y
    global g_base_scale_factor, g_display_window_width, g_display_window_height
    global g_orig_image_height, g_orig_image_width, precomputed_image

    if original_image is None:
        return

    g_orig_image_height, g_orig_image_width = original_image.shape[:2]
    scale_w = MAX_DISPLAY_WIDTH / g_orig_image_width
    scale_h = MAX_DISPLAY_HEIGHT / g_orig_image_height
    g_base_scale_factor = min(scale_w, scale_h)
    if g_base_scale_factor > 1.0:
        g_base_scale_factor = 1.0

    g_display_window_width = int(g_orig_image_width * g_base_scale_factor)
    g_display_window_height = int(g_orig_image_height * g_base_scale_factor)
    g_user_zoom_level = 1.0
    g_view_center_orig_x = g_orig_image_width / 2.0
    g_view_center_orig_y = g_orig_image_height / 2.0

    # Precompute image at current zoom level
    effective_scale = g_base_scale_factor * g_user_zoom_level
    precomputed_width = int(g_orig_image_width * effective_scale)
    precomputed_height = int(g_orig_image_height * effective_scale)
    precomputed_image = cv2.resize(
        original_image, (precomputed_width, precomputed_height), interpolation=cv2.INTER_LINEAR
    )


def get_current_view_image_and_draw():
    """Generates the visible image portion and draws points using precomputed image."""
    global original_image, precomputed_image, current_points, g_display_window_name
    global g_display_window_width, g_display_window_height
    global g_base_scale_factor, g_user_zoom_level
    global g_view_center_orig_x, g_view_center_orig_y
    global g_orig_image_width, g_orig_image_height

    if original_image is None or precomputed_image is None:
        black_screen = np.zeros((MAX_DISPLAY_HEIGHT, MAX_DISPLAY_WIDTH, 3), dtype=np.uint8)
        cv2.imshow(g_display_window_name, black_screen)
        return

    effective_scale = g_base_scale_factor * g_user_zoom_level
    view_width_orig = g_display_window_width / effective_scale
    view_height_orig = g_display_window_height / effective_scale
    view_tl_orig_x = g_view_center_orig_x - (view_width_orig / 2.0)
    view_tl_orig_y = g_view_center_orig_y - (view_height_orig / 2.0)
    view_br_orig_x = view_tl_orig_x + view_width_orig
    view_br_orig_y = view_tl_orig_y + view_height_orig

    display_canvas = np.zeros(
        (g_display_window_height, g_display_window_width, original_image.shape[2]), dtype=original_image.dtype
    )

    # Convert original image coordinates to precomputed image coordinates
    src_x1 = max(0, int(round(view_tl_orig_x * effective_scale)))
    src_y1 = max(0, int(round(view_tl_orig_y * effective_scale)))
    src_x2 = min(precomputed_image.shape[1], int(round(view_br_orig_x * effective_scale)))
    src_y2 = min(precomputed_image.shape[0], int(round(view_br_orig_y * effective_scale)))

    if src_x1 < src_x2 and src_y1 < src_y2:
        source_patch = precomputed_image[src_y1:src_y2, src_x1:src_x2]
        target_tl_disp_x = int(round((src_x1 / effective_scale - view_tl_orig_x) * effective_scale))
        target_tl_disp_y = int(round((src_y1 / effective_scale - view_tl_orig_y) * effective_scale))
        target_w_disp = src_x2 - src_x1
        target_h_disp = src_y2 - src_y1

        paste_x1 = max(0, target_tl_disp_x)
        paste_y1 = max(0, target_tl_disp_y)
        paste_x2 = min(g_display_window_width, target_tl_disp_x + target_w_disp)
        paste_y2 = min(g_display_window_height, target_tl_disp_y + target_h_disp)
        patch_crop_x1 = max(0, -target_tl_disp_x) if target_tl_disp_x < 0 else 0
        patch_crop_y1 = max(0, -target_tl_disp_y) if target_tl_disp_y < 0 else 0
        patch_crop_x2 = source_patch.shape[1] - max(0, (target_tl_disp_x + target_w_disp) - g_display_window_width)
        patch_crop_y2 = source_patch.shape[0] - max(0, (target_tl_disp_y + target_h_disp) - g_display_window_height)

        if (
            paste_x1 < paste_x2
            and paste_y1 < paste_y2
            and patch_crop_x1 < patch_crop_x2
            and patch_crop_y1 < patch_crop_y2
        ):
            display_canvas[paste_y1:paste_y2, paste_x1:paste_x2] = source_patch[
                patch_crop_y1:patch_crop_y2, patch_crop_x1:patch_crop_x2
            ]

    # Draw points
    for i, (orig_pt_x, orig_pt_y) in enumerate(current_points):
        disp_pt_x = (orig_pt_x - view_tl_orig_x) * effective_scale
        disp_pt_y = (orig_pt_y - view_tl_orig_y) * effective_scale
        if 0 <= disp_pt_x < g_display_window_width and 0 <= disp_pt_y < g_display_window_height:
            cv2.circle(display_canvas, (int(round(disp_pt_x)), int(round(disp_pt_y))), POINT_RADIUS, POINT_COLOR, -1)
            cv2.circle(display_canvas, (int(round(disp_pt_x)), int(round(disp_pt_y))), 1, (255, 255, 255), -1)
            cv2.putText(
                display_canvas,
                str(i + 1),
                (int(round(disp_pt_x)), int(round(disp_pt_y))),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                TEXT_COLOR,
                1,
            )

    cv2.imshow(g_display_window_name, display_canvas)


def mouse_callback(event, x, y, flags, param):
    """Handles mouse events for point selection, zoom, and pan."""
    global current_points, original_image, precomputed_image
    global g_user_zoom_level, g_view_center_orig_x, g_view_center_orig_y
    global g_is_panning, g_pan_start_mouse_x, g_pan_start_mouse_y
    global g_pan_start_view_center_x, g_pan_start_view_center_y
    global g_base_scale_factor, g_display_window_width, g_display_window_height
    global g_orig_image_width, g_orig_image_height

    if original_image is None:
        return

    # Point Selection (Left Click)
    if event == cv2.EVENT_LBUTTONDOWN:
        effective_scale = g_base_scale_factor * g_user_zoom_level
        view_width_orig = g_display_window_width / effective_scale
        view_height_orig = g_display_window_height / effective_scale
        view_tl_orig_x = g_view_center_orig_x - (view_width_orig / 2.0)
        view_tl_orig_y = g_view_center_orig_y - (view_height_orig / 2.0)

        original_pt_x = view_tl_orig_x + (x / effective_scale)
        original_pt_y = view_tl_orig_y + (y / effective_scale)
        original_pt_x = max(0.0, min(original_pt_x, float(g_orig_image_width - 1)))
        original_pt_y = max(0.0, min(original_pt_y, float(g_orig_image_height - 1)))

        current_points.append((int(round(original_pt_x)), int(round(original_pt_y))))
        print(f"Clicked display: ({x}, {y}) -> Original: ({current_points[-1][0]}, {current_points[-1][1]})")
        get_current_view_image_and_draw()

    # Zoom (Mouse Wheel)
    elif event == cv2.EVENT_MOUSEWHEEL:
        effective_scale_before = g_base_scale_factor * g_user_zoom_level
        view_width_orig_before = g_display_window_width / effective_scale_before
        view_height_orig_before = g_display_window_height / effective_scale_before
        view_tl_orig_x_before = g_view_center_orig_x - (view_width_orig_before / 2.0)
        view_tl_orig_y_before = g_view_center_orig_y - (view_height_orig_before / 2.0)
        mouse_at_orig_x = view_tl_orig_x_before + (x / effective_scale_before)
        mouse_at_orig_y = view_tl_orig_y_before + (y / effective_scale_before)

        if flags > 0:  # Zoom in
            g_user_zoom_level *= ZOOM_CHANGE_FACTOR
        else:  # Zoom out
            g_user_zoom_level /= ZOOM_CHANGE_FACTOR

        g_user_zoom_level = max(MIN_USER_ZOOM, min(g_user_zoom_level, MAX_USER_ZOOM))
        effective_scale_after = g_base_scale_factor * g_user_zoom_level
        g_view_center_orig_x = mouse_at_orig_x + (0.5 * g_display_window_width - x) / effective_scale_after
        g_view_center_orig_y = mouse_at_orig_y + (0.5 * g_display_window_height - y) / effective_scale_after

        # Update precomputed image
        precomputed_width = int(g_orig_image_width * effective_scale_after)
        precomputed_height = int(g_orig_image_height * effective_scale_after)
        precomputed_image = cv2.resize(
            original_image, (precomputed_width, precomputed_height), interpolation=cv2.INTER_LINEAR
        )
        get_current_view_image_and_draw()

    # Pan (Right Mouse Button Drag)
    elif event == cv2.EVENT_RBUTTONDOWN:
        g_is_panning = True
        g_pan_start_mouse_x = x
        g_pan_start_mouse_y = y
        g_pan_start_view_center_x = g_view_center_orig_x
        g_pan_start_view_center_y = g_view_center_orig_y

    elif event == cv2.EVENT_MOUSEMOVE and g_is_panning:
        effective_scale = g_base_scale_factor * g_user_zoom_level
        mouse_dx_display = x - g_pan_start_mouse_x
        mouse_dy_display = y - g_pan_start_mouse_y
        delta_orig_x = mouse_dx_display / effective_scale
        delta_orig_y = mouse_dy_display / effective_scale
        g_view_center_orig_x = g_pan_start_view_center_x - delta_orig_x
        g_view_center_orig_y = g_pan_start_view_center_y - delta_orig_y
        get_current_view_image_and_draw()

    elif event == cv2.EVENT_RBUTTONUP:
        g_is_panning = False


def main():
    global current_points, original_image, g_display_window_name, precomputed_image
    global g_orig_image_width, g_orig_image_height

    if not IMAGE_DIR.is_dir():
        print(f"Error: Directory '{IMAGE_DIR}' not found.")
        return

    image_files = sorted([f for f in IMAGE_DIR.iterdir() if f.suffix.lower() in SUPPORTED_EXTENSIONS])

    if not image_files:
        print(f"No supported images found in '{IMAGE_DIR}'.")
        return

    all_annotations = []
    quit_app = False

    for image_path in image_files:
        if quit_app:
            break

        original_image = cv2.imread(image_path.as_posix())

        if original_image is None:
            print(f"Warning: Could not load image: {image_path.as_posix()}")
            continue

        current_points = []
        reset_zoom_pan_state()
        cv2.namedWindow(g_display_window_name, cv2.WINDOW_NORMAL)
        cv2.resizeWindow(g_display_window_name, g_display_window_width, g_display_window_height)
        cv2.setMouseCallback(g_display_window_name, mouse_callback)

        print(f"\n--- Now annotating: {image_path.name} ---")
        print(
            f"Original Dims: {g_orig_image_width}x{g_orig_image_height}, Display Dims:"
            f" {g_display_window_width}x{g_display_window_height}"
        )
        print("Left-click: Add point. Mouse Wheel: Zoom. Right-Drag: Pan.")
        print("N:Next U:Undo R:ResetPoints Z:ResetView Q/Esc:Quit")

        get_current_view_image_and_draw()

        while True:
            key = cv2.waitKey(20) & 0xFF

            if key == ord("n"):
                if current_points:
                    print(f"Saved {len(current_points)} points for {image_path.name}.")
                    all_annotations.append({"filename": image_path.name, "points": list(current_points)})
                break

            elif key == ord("u"):
                if current_points:
                    current_points.pop()
                    print("Undid last point.")
                    get_current_view_image_and_draw()
                else:
                    print("No points to undo.")

            elif key == ord("r"):
                current_points = []
                print("Reset all points for this image.")
                get_current_view_image_and_draw()

            elif key == ord("z"):
                reset_zoom_pan_state()
                print("Reset view (zoom/pan).")
                get_current_view_image_and_draw()

            elif key == ord("q") or key == 27:
                if current_points:
                    print(f"Saved {len(current_points)} points for {image_path.name} before quitting.")
                    all_annotations.append({"filename": image_path.name, "points": list(current_points)})
                quit_app = True
                break

        cv2.destroyWindow(g_display_window_name)

    if all_annotations:
        with open(OUTPUT_FILE, "w") as f:
            json.dump(all_annotations, f, indent=2)
        print(f"\nAll annotations saved to: {OUTPUT_FILE}")
    else:
        print("\nNo annotations were made or saved.")

    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
