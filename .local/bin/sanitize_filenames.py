import os
import re
import argparse

def sanitize_filename(filename):
    """Sanitize a filename for cross-system compatibility."""
    # Extract the file extension and base name
    base, ext = os.path.splitext(filename)
    
    # Replace spaces and special characters with underscores
    sanitized = re.sub(r'[\s:;,\'&"<>|?*\\\/]', '_', base)
    
    # Remove any remaining unsafe characters
    sanitized = re.sub(r'[^\w\-_\.]', '', sanitized)
    
    # Avoid reserved names (Windows-specific)
    reserved_names = {'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 
                      'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 
                      'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'}
    if sanitized.upper() in reserved_names:
        sanitized = f"_{sanitized}"
    
    # Limit length (255 is typical max for most filesystems)
    max_len = 200  # Conservative limit to account for path
    if len(sanitized) > max_len:
        sanitized = sanitized[:max_len]
    
    # Remove leading/trailing underscores or periods
    sanitized = sanitized.strip('_').strip('.')
    
    # If sanitized name is empty, provide a default
    if not sanitized:
        sanitized = "unnamed"
    
    return sanitized + ext

def sanitize_files_in_directory(directory):
    """Sanitize all filenames in the given directory."""
    for filename in os.listdir(directory):
        filepath = os.path.join(directory, filename)
        if os.path.isfile(filepath):
            sanitized_name = sanitize_filename(filename)
            if sanitized_name != filename:
                new_filepath = os.path.join(directory, sanitized_name)
                # Handle naming conflicts
                counter = 1
                while os.path.exists(new_filepath):
                    base, ext = os.path.splitext(sanitized_name)
                    new_filepath = os.path.join(directory, f"{base}_{counter}{ext}")
                    counter += 1
                print(f"Renaming: {filename} -> {os.path.basename(new_filepath)}")
                os.rename(filepath, new_filepath)

def main():
    parser = argparse.ArgumentParser(description="Sanitize filenames in a directory.")
    parser.add_argument("directory", help="Directory containing files to sanitize")
    args = parser.parse_args()
    
    if not os.path.isdir(args.directory):
        print(f"Error: {args.directory} is not a valid directory")
        return
    
    sanitize_files_in_directory(args.directory)
    print("Sanitization complete.")

if __name__ == "__main__":
    main()
