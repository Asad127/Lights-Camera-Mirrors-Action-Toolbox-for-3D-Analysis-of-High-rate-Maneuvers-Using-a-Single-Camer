import argparse
from pathlib import Path

import numpy as np
import scipy.io as sio


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert a MATLAB .mat file to Python data structures.")
    parser.add_argument("path_mat", type=str, help="Path to the .mat file")
    parser.add_argument("--path_py", type=str, help="Path to save the Python file")
    parsed_args = parser.parse_args()
    if parsed_args.path_py is None:
        parsed_args.path_py = parsed_args.path_mat.with_suffix(".py")
    return parsed_args


def convert_mat_to_python(path_mat: Path) -> dict:
    """
    Convert a MATLAB .mat file to Python data structures, using NumPy arrays for numerical data.

    Args:
        path_matfile (str | Path): Path to the .mat file

    Returns:
        dict: Dictionary containing the converted data
    """
    try:
        # Load the .mat file
        mat_data = sio.loadmat(path_mat, simplify_cells=True)

        # Remove MATLAB-specific metadata if present
        mat_data.pop("__header__", None)
        mat_data.pop("__version__", None)
        mat_data.pop("__globals__", None)

        # Process each variable in the .mat file
        def convert_item(item):
            # Convert MATLAB arrays to NumPy arrays
            if isinstance(item, np.ndarray):
                # Ensure proper data type conversion
                if item.dtype.kind in ["i", "u", "f"]:  # Numeric types
                    return item
                elif item.dtype == object:  # Handle cell arrays
                    return np.array([convert_item(sub_item) for sub_item in item], dtype=object)
                else:
                    return item
            # Convert MATLAB structs to Python dictionaries
            elif isinstance(item, dict):
                return {key: convert_item(value) for key, value in item.items()}
            # Handle scalar values
            elif isinstance(item, (int, float, str)):
                return item
            # Handle lists or other iterables
            elif isinstance(item, (list, tuple)):
                return [convert_item(sub_item) for sub_item in item]
            else:
                return item  # Return unchanged if type is not specifically handled

        # Convert all items in the loaded .mat data
        converted_data = {key: convert_item(value) for key, value in mat_data.items()}

        return converted_data

    except FileNotFoundError:
        print(f"Error: File '{path_mat}' not found.")
        return None
    except Exception as e:
        print(f"Error processing .mat file: {str(e)}")
        return None


def save_to_python_file(data: dict, path_py: Path) -> None:
    """
    Save the converted data to a Python file for inspection or reuse.

    Args:
        data (dict): Converted data from .mat file
        path_outfile (str | Path): Path to save the Python file
    """
    output_path = Path(path_py)
    output_path.write_text(
        "# Converted MATLAB data\nimport numpy as np\n\n"
        + "\n".join(
            (
                f"{key} = np.array({value.tolist()}, dtype={value.dtype})"
                if isinstance(value, np.ndarray)
                else f"{key} = {value}"
            )
            for key, value in data.items()
        )
    )


if __name__ == "__main__":
    args = parse_args()
    path_mat = Path(args.path_mat)
    path_py = Path(args.path_py)

    if path_mat.exists():
        data = convert_mat_to_python(path_mat)
        if data:
            print("Converted data:")
            for key, value in data.items():
                print(f"{key}: {type(value)}")
            save_to_python_file(data, path_py)
            print(f"Data saved to {path_py}")
    else:
        print(f"Please provide a valid .mat file path.")
