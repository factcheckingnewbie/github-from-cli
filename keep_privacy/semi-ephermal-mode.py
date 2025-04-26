#!/usr/bin/env python3
import subprocess
import sys
import shlex

def main():
    """
    Usage:
      ./run_ephemeral_mode.py <script-to-run> [default arguments...]

    This script executes the given command in the alternate screen buffer.
    It prompts for additional arguments after switching to the alternate screen,
    so that any input you provide isn’t visible when you return to your primary screen.
    After the command completes, its output (captured as strings) is printed to the primary screen.
    """
    if len(sys.argv) < 2:
        print("Usage: {} <script-to-run> [default arguments...]".format(sys.argv[0]))
        sys.exit(1)
    
    target_script = sys.argv[1]
    default_args = sys.argv[2:]
    
    # Build the base command string from the target script and any default arguments.
    cmd = shlex.quote(target_script)
    if default_args:
        cmd += " " + " ".join(shlex.quote(arg) for arg in default_args)

    # Switch to the alternate screen buffer.
    sys.stdout.write("\033[?1049h")
    sys.stdout.flush()
    
    # Now prompt for additional arguments within the alternate screen.
    user_input = input("Enter additional arguments (or press Enter to use defaults): ").strip()
    if user_input:
        cmd += " " + user_input

    captured_output = ""
    try:
        # Start the command so that shell metacharacters like redirection work.
        proc = subprocess.Popen(cmd, shell=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                bufsize=1, universal_newlines=True)
        for line in proc.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()
            captured_output += line
        proc.stdout.close()
        proc.wait()
    finally:
        # Switch back to the primary screen buffer.
        sys.stdout.write("\033[?1049l")
        sys.stdout.flush()
        # Print only the captured output.
        print(captured_output)

if __name__ == "__main__":
    main()

