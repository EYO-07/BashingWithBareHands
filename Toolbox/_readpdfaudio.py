#!/usr/bin/env python3
# BEGIN _readpdfaudio.py

import sys
import os
import tempfile
import pdftotext
from gtts import gTTS
import subprocess

def main():
    # --- Argument Parsing ---
    if len(sys.argv) < 2:
        print("Usage: _readpdfaudio.py <pdfbook> [--pausepages=N] [--startingpage=M] [--language=...]")
        sys.exit(1)
    pdf_path = sys.argv[1]
    pause_interval = 1      # Default: no pause (0)
    start_page = 1          # Default: start at page 1
    language="en"
    # Parse optional flags
    for arg in sys.argv[2:]:
        if arg.startswith("--pausepages="):
            try:
                pause_interval = int(arg.split("=")[1])
            except ValueError:
                print("Error: --pausepages must be an integer.")
                sys.exit(1)
        elif arg.startswith("--startingpage="):
            try:
                start_page = int(arg.split("=")[1])
            except ValueError:
                print("Error: --startingpage must be an integer.")
                sys.exit(1)
        elif arg.startswith("--language="):
            try:
                language = str(arg.split("=")[1])
            except ValueError:
                print("Error: --startingpage must be an integer.")
                sys.exit(1)        
    if not os.path.isfile(pdf_path):
        print(f"Error: File '{pdf_path}' not found.")
        sys.exit(1)
    # --- PDF Extraction ---
    try:
        with open(pdf_path, "rb") as f:
            pdf = pdftotext.PDF(f)
    except Exception as e:
        print(f"Error reading PDF: {e}")
        sys.exit(1)
    total_pages = len(pdf)
    # Validate start page
    if start_page < 1:
        start_page = 1
    if start_page > total_pages:
        print(f"Error: Starting page ({start_page}) is greater than total pages ({total_pages}).")
        sys.exit(1)
    print(f"Loaded PDF: {total_pages} pages. Starting from page {start_page}...")
    # --- Playback Loop ---
    # Enumerate starts at 0, so we slice or skip based on start_page
    for i in range(total_pages):
        page_num = i + 1
        # Skip pages before the starting page
        if page_num < start_page:
            continue
        page_text = pdf[i]
        # Skip empty pages
        if not page_text.strip():
            continue
        print(f"Reading Page {page_num}/{total_pages}...")
        try:
            # Generate Audio
            print(f"... Generating Audio with gTTS")
            tts = gTTS(page_text, lang=language)
            # Save to temporary file
            print(f"... Creating Temporary File")
            with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as fp:
                temp_mp3 = fp.name
                tts.save(temp_mp3)
            # Play Audio with VLC
            print(f"... Starting Audio")
            subprocess.run(["cvlc", "--play-and-exit", "--no-loop", temp_mp3], 
                           stdout=subprocess.DEVNULL, 
                           stderr=subprocess.DEVNULL)
            # Cleanup temp file
            os.unlink(temp_mp3)
        except Exception as e:
            print(f"\nError on page {page_num}: {e}")
            continue
        # --- Pause & Quit Logic ---
        # Pause if interval is set, we aren't at the last page, and we hit the multiple
        if pause_interval > 0 and page_num < total_pages and (page_num % pause_interval == 0):
            print(f"\n--- Paused after page {page_num} ---")
            user_input = input("Press Enter to continue (or type 'q' to quit)...")
            if user_input.lower() == 'q':
                print("\nQuitting playback.")
                # Cleanup any remaining temp files if necessary (none here as we deleted immediately)
                sys.exit(0)
    print("\nFinished reading the book.")

if __name__ == "__main__":
    main()

# END _readpdfaudio.py   