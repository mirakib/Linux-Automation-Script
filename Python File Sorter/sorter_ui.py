import os
import shutil
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext


class FileSorterApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Keyword File Sorter")
        self.root.geometry("600x550")

        # Variables
        self.source_path = tk.StringVar()
        self.dest_path = tk.StringVar()
        self.keywords = tk.StringVar()
        self.operation_mode = tk.StringVar(value="copy")  # Default to copy
        self.auto_folder_var = tk.BooleanVar(value=False)

        # --- UI Layout ---

        # 1. Source Selection
        tk.Label(root, text="1. Select Source Folder:", font=("Arial", 10, "bold")).pack(anchor="w", padx=10,
                                                                                         pady=(10, 0))
        frame_src = tk.Frame(root)
        frame_src.pack(fill="x", padx=10, pady=5)
        tk.Entry(frame_src, textvariable=self.source_path).pack(side="left", fill="x", expand=True)
        tk.Button(frame_src, text="Browse", command=self.browse_source).pack(side="right", padx=(5, 0))

        # 2. Keywords
        tk.Label(root, text="2. Enter Keywords (comma separated):", font=("Arial", 10, "bold")).pack(anchor="w",
                                                                                                     padx=10,
                                                                                                     pady=(10, 0))
        tk.Label(root, text="(e.g., invoice, receipt, 2023)", font=("Arial", 8, "italic")).pack(anchor="w", padx=10)
        tk.Entry(root, textvariable=self.keywords).pack(fill="x", padx=10, pady=5)

        # 3. Destination Selection
        tk.Label(root, text="3. Destination Options:", font=("Arial", 10, "bold")).pack(anchor="w", padx=10,
                                                                                        pady=(10, 0))

        # Checkbox for auto-creating folder
        tk.Checkbutton(root, text="Create a new folder inside Source named 'Sorted_Files'",
                       variable=self.auto_folder_var, command=self.toggle_dest_entry).pack(anchor="w", padx=20)

        # Manual Destination Entry
        self.frame_dest = tk.Frame(root)
        self.frame_dest.pack(fill="x", padx=10, pady=5)
        self.dest_entry = tk.Entry(self.frame_dest, textvariable=self.dest_path)
        self.dest_entry.pack(side="left", fill="x", expand=True)
        self.dest_btn = tk.Button(self.frame_dest, text="Browse Destination", command=self.browse_dest)
        self.dest_btn.pack(side="right", padx=(5, 0))

        # 4. Action Type (Copy vs Move)
        tk.Label(root, text="4. Action:", font=("Arial", 10, "bold")).pack(anchor="w", padx=10, pady=(10, 0))
        frame_ops = tk.Frame(root)
        frame_ops.pack(anchor="w", padx=20, pady=5)
        tk.Radiobutton(frame_ops, text="Copy Files", variable=self.operation_mode, value="copy").pack(side="left",
                                                                                                      padx=10)
        tk.Radiobutton(frame_ops, text="Cut (Move) Files", variable=self.operation_mode, value="move").pack(side="left",
                                                                                                            padx=10)

        # 5. Run Button
        tk.Button(root, text="START SORTING", bg="#4CAF50", fg="white", font=("Arial", 12, "bold"),
                  command=self.run_sort).pack(pady=20, ipadx=20)

        # 6. Log Window
        tk.Label(root, text="Activity Log:", font=("Arial", 9)).pack(anchor="w", padx=10)
        self.log_area = scrolledtext.ScrolledText(root, height=10, state='disabled')
        self.log_area.pack(fill="both", expand=True, padx=10, pady=(0, 10))

    def browse_source(self):
        folder = filedialog.askdirectory()
        if folder:
            self.source_path.set(folder)

    def browse_dest(self):
        folder = filedialog.askdirectory()
        if folder:
            self.dest_path.set(folder)

    def toggle_dest_entry(self):
        # Enable/Disable destination inputs based on checkbox
        if self.auto_folder_var.get():
            self.dest_entry.config(state='disabled')
            self.dest_btn.config(state='disabled')
        else:
            self.dest_entry.config(state='normal')
            self.dest_btn.config(state='normal')

    def log(self, message):
        self.log_area.config(state='normal')
        self.log_area.insert(tk.END, message + "\n")
        self.log_area.see(tk.END)
        self.log_area.config(state='disabled')
        # Force UI update so app doesn't freeze during loop
        self.root.update()

    def run_sort(self):
        src = self.source_path.get()
        raw_keys = self.keywords.get()
        mode = self.operation_mode.get()
        auto_folder = self.auto_folder_var.get()
        manual_dest = self.dest_path.get()

        # --- Validation ---
        if not src or not os.path.isdir(src):
            messagebox.showerror("Error", "Please select a valid Source folder.")
            return

        if not raw_keys.strip():
            messagebox.showerror("Error", "Please enter at least one keyword.")
            return

        # --- Determine Destination ---
        if auto_folder:
            # Create a folder inside the source
            final_dest = os.path.join(src, "Sorted_Files")
        else:
            if not manual_dest:
                messagebox.showerror("Error",
                                     "Please select a destination folder or check the 'Create new folder' box.")
                return
            final_dest = manual_dest

        # Create destination if it doesn't exist
        if not os.path.exists(final_dest):
            try:
                os.makedirs(final_dest)
                self.log(f"Created folder: {final_dest}")
            except OSError as e:
                messagebox.showerror("Error", f"Could not create destination folder: {e}")
                return

        # --- Processing ---
        keyword_list = [k.strip().lower() for k in raw_keys.split(',')]
        files_processed = 0

        self.log("--- Starting Operation ---")

        try:
            for filename in os.listdir(src):
                full_file_path = os.path.join(src, filename)

                # Skip if it's a directory
                if os.path.isdir(full_file_path):
                    continue

                # Check for keywords (Case Insensitive)
                if any(key in filename.lower() for key in keyword_list):
                    dest_file_path = os.path.join(final_dest, filename)

                    # Handle duplicate names to prevent overwrite crashes
                    if os.path.exists(dest_file_path):
                        base, extension = os.path.splitext(filename)
                        dest_file_path = os.path.join(final_dest, f"{base}_copy{extension}")

                    if mode == "copy":
                        shutil.copy2(full_file_path, dest_file_path)
                        self.log(f"Copied: {filename}")
                    elif mode == "move":
                        shutil.move(full_file_path, dest_file_path)
                        self.log(f"Moved: {filename}")

                    files_processed += 1

            messagebox.showinfo("Done", f"Operation Complete!\nProcessed {files_processed} files.")
            self.log(f"--- Finished. Total: {files_processed} ---")

        except Exception as e:
            messagebox.showerror("Error", f"An unexpected error occurred: {e}")


if __name__ == "__main__":
    root = tk.Tk()
    app = FileSorterApp(root)
    root.mainloop()
