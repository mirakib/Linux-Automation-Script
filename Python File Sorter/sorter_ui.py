import os
import shutil
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext


class FileSorterApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Keyword File Sorter")
        self.root.geometry("700x650")  # Increased size slightly for better spacing

        # Variables
        self.source_path = tk.StringVar()
        self.dest_path = tk.StringVar()
        self.keywords = tk.StringVar()
        self.new_folder_name = tk.StringVar(value="Sorted_Files")  # Default name
        self.operation_mode = tk.StringVar(value="copy")
        self.create_subfolder_var = tk.BooleanVar(value=False)

        # --- UI Layout ---
        # Main container for ~20% margin simulation
        # Window width ~700. 20% is ~140px. Using padx=80 ensures a nice centered look.
        main_frame = tk.Frame(root)
        main_frame.pack(fill="both", expand=True, padx=80, pady=20)

        # 1. Source Selection
        tk.Label(main_frame, text="1. Select Source Folder:", font=("Arial", 10, "bold")).pack(anchor="w", pady=(10, 5))

        frame_src = tk.Frame(main_frame)
        frame_src.pack(fill="x", pady=5)
        tk.Entry(frame_src, textvariable=self.source_path).pack(side="left", fill="x", expand=True)
        tk.Button(frame_src, text="Browse", command=self.browse_source).pack(side="right", padx=(5, 0))

        # 2. Keywords
        tk.Label(main_frame, text="2. Enter Keywords (comma separated):", font=("Arial", 10, "bold")).pack(anchor="w",
                                                                                                           pady=(15, 0))
        tk.Label(main_frame, text="(e.g., invoice, receipt, 2023)", font=("Arial", 8, "italic"), fg="gray").pack(
            anchor="w")
        tk.Entry(main_frame, textvariable=self.keywords).pack(fill="x", pady=5)

        # 3. Destination Selection
        tk.Label(main_frame, text="3. Destination Base Folder:", font=("Arial", 10, "bold")).pack(anchor="w",
                                                                                                  pady=(15, 5))

        frame_dest = tk.Frame(main_frame)
        frame_dest.pack(fill="x", pady=5)
        tk.Entry(frame_dest, textvariable=self.dest_path).pack(side="left", fill="x", expand=True)
        tk.Button(frame_dest, text="Browse", command=self.browse_dest).pack(side="right", padx=(5, 0))

        # 3b. New Folder Option
        frame_sub = tk.Frame(main_frame)
        frame_sub.pack(fill="x", pady=10)

        tk.Checkbutton(frame_sub, text="Create new subfolder?",
                       variable=self.create_subfolder_var, command=self.toggle_folder_name).pack(side="left")

        self.entry_folder_name = tk.Entry(frame_sub, textvariable=self.new_folder_name, state='disabled', fg="black")
        self.entry_folder_name.pack(side="right", fill="x", expand=True, padx=(10, 0))

        # 4. Action Type (Copy vs Move)
        tk.Label(main_frame, text="4. Action:", font=("Arial", 10, "bold")).pack(anchor="w", pady=(15, 5))
        frame_ops = tk.Frame(main_frame)
        frame_ops.pack(anchor="w", pady=5)
        tk.Radiobutton(frame_ops, text="Copy Files", variable=self.operation_mode, value="copy").pack(side="left",
                                                                                                      padx=(0, 20))
        tk.Radiobutton(frame_ops, text="Cut (Move) Files", variable=self.operation_mode, value="move").pack(side="left")

        # 5. Run Button
        tk.Button(main_frame, text="START SORTING", bg="#4CAF50", fg="white", font=("Arial", 11, "bold"),
                  command=self.run_sort, relief="flat", cursor="hand2").pack(pady=25, fill="x")

        # 6. Log Window
        tk.Label(main_frame, text="Activity Log:", font=("Arial", 9)).pack(anchor="w")
        self.log_area = scrolledtext.ScrolledText(main_frame, height=8, state='disabled', font=("Consolas", 9))
        self.log_area.pack(fill="both", expand=True, pady=(5, 0))

    def browse_source(self):
        folder = filedialog.askdirectory()
        if folder:
            self.source_path.set(folder)

    def browse_dest(self):
        folder = filedialog.askdirectory()
        if folder:
            self.dest_path.set(folder)

    def toggle_folder_name(self):
        if self.create_subfolder_var.get():
            self.entry_folder_name.config(state='normal')
        else:
            self.entry_folder_name.config(state='disabled')

    def log(self, message):
        self.log_area.config(state='normal')
        self.log_area.insert(tk.END, message + "\n")
        self.log_area.see(tk.END)
        self.log_area.config(state='disabled')
        self.root.update()

    def run_sort(self):
        src = self.source_path.get()
        dest_base = self.dest_path.get()
        raw_keys = self.keywords.get()
        mode = self.operation_mode.get()
        create_sub = self.create_subfolder_var.get()
        sub_name = self.new_folder_name.get()

        # --- Validation ---
        if not src or not os.path.isdir(src):
            messagebox.showerror("Error", "Please select a valid Source folder.")
            return

        if not raw_keys.strip():
            messagebox.showerror("Error", "Please enter at least one keyword.")
            return

        if not dest_base:
            messagebox.showerror("Error", "Please select a Destination Base folder.")
            return

        # --- Determine Final Destination ---
        if create_sub:
            if not sub_name.strip():
                messagebox.showerror("Error", "Please enter a name for the new folder.")
                return
            final_dest = os.path.join(dest_base, sub_name)
        else:
            final_dest = dest_base

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

        self.log(f"--- Starting {mode.upper()} operation ---")
        self.log(f"Source: {src}")
        self.log(f"Target: {final_dest}")

        try:
            for filename in os.listdir(src):
                full_file_path = os.path.join(src, filename)

                # Skip if it's a directory
                if os.path.isdir(full_file_path):
                    continue

                # Check for keywords (Case Insensitive)
                if any(key in filename.lower() for key in keyword_list):
                    dest_file_path = os.path.join(final_dest, filename)

                    # Handle duplicate names
                    if os.path.exists(dest_file_path):
                        base, extension = os.path.splitext(filename)
                        # Add counter to handle multiple copies
                        counter = 1
                        while os.path.exists(os.path.join(final_dest, f"{base}_copy{counter}{extension}")):
                            counter += 1
                        dest_file_path = os.path.join(final_dest, f"{base}_copy{counter}{extension}")

                    try:
                        if mode == "copy":
                            shutil.copy2(full_file_path, dest_file_path)
                            self.log(f"Copied: {filename}")
                        elif mode == "move":
                            shutil.move(full_file_path, dest_file_path)
                            self.log(f"Moved: {filename}")

                        files_processed += 1
                    except Exception as file_error:
                        self.log(f"Error processing {filename}: {file_error}")

            messagebox.showinfo("Done", f"Operation Complete!\nProcessed {files_processed} files.")
            self.log(f"--- Finished. Total: {files_processed} ---")

        except Exception as e:
            messagebox.showerror("Error", f"An unexpected error occurred: {e}")


if __name__ == "__main__":
    root = tk.Tk()
    app = FileSorterApp(root)
    root.mainloop()
