#!/usr/bin/python3

import subprocess
import sys
from pathlib import Path

packer_scripts_directory = "packer/scripts"

class Shell_Check_Linter:
    linter = "shellcheck"

    def lint( self, file_path):
        # Lists are safer than string literals
        command = [self.linter, file_path]

        # shellcheck's exit code doubles as its result: 0 = clean, 1 = issues
        # found (expected!), 2 = bad CLI usage, 3 = shellcheck itself errored.
        # check=True would treat "found issues" the same as "linter crashed".
        result = subprocess.run(
            command,
            capture_output = True,
            text = True,
            check = False
        )

        if result.stdout:
            print( result.stdout )

        # 0 is clean (do nothing), 1 = linting issues, >= 2 is shellcheck choking
        if result.returncode == 0:
            return True
        if result.returncode == 1:
            return False
        elif result.returncode > 1:
            print( result.stderr, file = sys.stderr )
            result.check_returncode()
            return False

# -----
# Program execution begins here
# -----

# We loop over each file, and as long as they pass, this stays false
found_issues = False
shell_checker_linter = Shell_Check_Linter()
target_directory = Path( packer_scripts_directory )

for file_path in sorted( target_directory.glob( "*" ) ):

    # If it's not a file, don't bother
    if file_path.is_file():
        print( f"Processing: {file_path.name}" )

        if not shell_checker_linter.lint( file_path ):
            found_issues = True

sys.exit( 1 if found_issues else 0 )
