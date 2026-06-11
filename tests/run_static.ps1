$ErrorActionPreference = "Stop"
python -m unittest discover -s tests/static -p "test_*.py"

