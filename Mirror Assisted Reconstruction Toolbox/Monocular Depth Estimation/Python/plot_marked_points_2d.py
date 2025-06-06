import json
from pathlib import Path

import cv2
import numpy as np

# Configuration
BASEDIR = "depth-anything-v2"
IMAGE_DIR = Path(BASEDIR, "color")
PATH_ANNOTATED_COORDINATES = Path(BASEDIR, "annotated_coordinates.json")
DISPLAY_MAX_WIDTH = 1280
DISPLAY_MAX_HEIGHT = 720
POINT_RADIUS = 2
# COLORs in BGR order.
PHYSICAL_POINT_COLOR = (0, 0, 255)
VIRTUAL_POINT_COLOR = (0, 255, 0)
TEXT_COLOR_PHYSICAL = (0, 0, 255)
TEXT_COLOR_VIRTUAL = (0, 255, 0)
MIN_USER_ZOOM = 0.5
MAX_USER_ZOOM = 20
ZOOM_CHANGE_FACTOR = 1.1

# Global state variables
original_image = None
precomputed_image = None
g_orig_image_height = 0
g_orig_image_width = 0
g_base_scale_factor = 1.0
g_user_zoom_level = 1.0
g_view_center_orig_x = 0.0
g_view_center_orig_y = 0.0
g_display_window_width = 0
g_display_window_height = 0
g_is_panning = False
g_pan_start_mouse_x = 0
g_pan_start_mouse_y = 0
g_pan_start_view_center_x = 0
g_pan_start_view_center_y = 0
g_display_window_name = "Image Viewer (Zoom/Pan)"
physical_image_points = []
virtual_image_points = []


def reset_zoom_pan_state():
    """Resets zoom and pan to initial fit for the current original_image."""
    global g_base_scale_factor, g_user_zoom_level, g_view_center_orig_x, g_view_center_orig_y
    global g_display_window_width, g_display_window_height, g_orig_image_width, g_orig_image_height
    global precomputed_image

    if original_image is None:
        return

    g_orig_image_height, g_orig_image_width = original_image.shape[:2]
    scale_w = DISPLAY_MAX_WIDTH / g_orig_image_width
    scale_h = DISPLAY_MAX_HEIGHT / g_orig_image_height
    g_base_scale_factor = min(scale_w, scale_h)
    if g_base_scale_factor > 1.0:
        g_base_scale_factor = 1.0

    g_display_window_width = int(g_orig_image_width * g_base_scale_factor)
    g_display_window_height = int(g_orig_image_height * g_base_scale_factor)
    g_user_zoom_level = 1.0
    g_view_center_orig_x = g_orig_image_width / 2.0
    g_view_center_orig_y = g_orig_image_height / 2.0

    # Precompute image at current zoom level.
    effective_scale = g_base_scale_factor * g_user_zoom_level
    precomputed_width = int(g_orig_image_width * effective_scale)
    precomputed_height = int(g_orig_image_height * effective_scale)
    precomputed_image = cv2.resize(
        original_image, (precomputed_width, precomputed_height), interpolation=cv2.INTER_LINEAR
    )


def get_current_view_image_and_draw():
    """Generates the visible image portion and draws points using precomputed image."""
    global original_image, precomputed_image, g_display_window_name, g_display_window_width, g_display_window_height
    global g_base_scale_factor, g_user_zoom_level, g_view_center_orig_x, g_view_center_orig_y
    global g_orig_image_width, g_orig_image_height, physical_image_points, virtual_image_points

    if original_image is None or precomputed_image is None:
        black_screen = np.zeros((DISPLAY_MAX_HEIGHT, DISPLAY_MAX_WIDTH, 3), dtype=np.uint8)
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

    # Convert original image coordinates to precomputed image coordinates.
    src_x1 = max(0, int(round(view_tl_orig_x * effective_scale)))
    src_y1 = max(0, int(round(view_tl_orig_y * effective_scale)))
    src_x2 = min(precomputed_image.shape[1], int(round(view_br_orig_x * effective_scale)))
    src_y2 = min(precomputed_image.shape[0], int(round(view_br_orig_y * effective_scale)))

    if src_x1 < src_x2 and src_y1 < src_y2:
        # Extract patch from precomputed image.
        source_patch = precomputed_image[src_y1:src_y2, src_x1:src_x2]

        # Calculate where to place the patch on the canvas.
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

    # Draw points.
    for i, (orig_pt_x, orig_pt_y) in enumerate(physical_image_points, start=1):
        disp_pt_x = (orig_pt_x - view_tl_orig_x) * effective_scale
        disp_pt_y = (orig_pt_y - view_tl_orig_y) * effective_scale
        if 0 <= disp_pt_x < g_display_window_width and 0 <= disp_pt_y < g_display_window_height:
            cv2.circle(
                display_canvas, (int(round(disp_pt_x)), int(round(disp_pt_y))), POINT_RADIUS, PHYSICAL_POINT_COLOR, -1
            )
            cv2.putText(
                display_canvas,
                str(i),
                (int(round(disp_pt_x)), int(round(disp_pt_y))),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                TEXT_COLOR_PHYSICAL,
                1,
            )

    for i, (orig_pt_x, orig_pt_y) in enumerate(virtual_image_points, start=1):
        disp_pt_x = (orig_pt_x - view_tl_orig_x) * effective_scale
        disp_pt_y = (orig_pt_y - view_tl_orig_y) * effective_scale
        if 0 <= disp_pt_x < g_display_window_width and 0 <= disp_pt_y < g_display_window_height:
            cv2.circle(
                display_canvas, (int(round(disp_pt_x)), int(round(disp_pt_y))), POINT_RADIUS, VIRTUAL_POINT_COLOR, -1
            )
            cv2.putText(
                display_canvas,
                str(i),
                (int(round(disp_pt_x)), int(round(disp_pt_y))),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                TEXT_COLOR_VIRTUAL,
                1,
            )

    cv2.imshow(g_display_window_name, display_canvas)


def mouse_callback(event, x, y, flags, param):
    """Handles mouse events for zoom and pan."""
    global g_user_zoom_level, g_view_center_orig_x, g_view_center_orig_y
    global g_is_panning, g_pan_start_mouse_x, g_pan_start_mouse_y
    global g_pan_start_view_center_x, g_pan_start_view_center_y
    global g_base_scale_factor, g_display_window_width, g_display_window_height
    global precomputed_image

    if original_image is None:
        return

    # Zoom (Mouse Wheel)
    if event == cv2.EVENT_MOUSEWHEEL:
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
    global original_image, g_display_window_name, physical_image_points, virtual_image_points, precomputed_image

    with open(PATH_ANNOTATED_COORDINATES, "r") as f:
        annotations = json.load(f)

    cv2.namedWindow(g_display_window_name, cv2.WINDOW_NORMAL)
    cv2.setMouseCallback(g_display_window_name, mouse_callback)

    for annotation in annotations:
        filename: str = annotation["filename"]
        points: list[list[int, int]] = annotation["points"]
        original_image = cv2.imread((IMAGE_DIR / filename).as_posix())

        if original_image is None:
            print(f"Failed to load image: {(IMAGE_DIR / filename).as_posix()}")
            continue

        physical_image_points = points[: len(points) // 2]
        virtual_image_points = points[len(points) // 2 :]
        reset_zoom_pan_state()
        cv2.resizeWindow(g_display_window_name, g_display_window_width, g_display_window_height)
        print(f"\n--- Displaying: {filename} ---")
        print(
            f"Original Dims: {g_orig_image_width}x{g_orig_image_height}, Display Dims:"
            f" {g_display_window_width}x{g_display_window_height}"
        )
        print("Mouse Wheel: Zoom. Right-Drag: Pan. Z: ResetView. ESC/Q: Next/Quit")

        while True:
            get_current_view_image_and_draw()
            key = cv2.waitKey(20) & 0xFF

            if key == ord("z"):  # Reset zoom and pan
                reset_zoom_pan_state()
                print("Reset view (zoom/pan).")
                get_current_view_image_and_draw()

            elif key in [ord("q"), 27]:  # Quit or next image (ESC)
                break

    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
