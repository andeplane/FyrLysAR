#!/bin/bash
#
# Setup script for local Fastlane environment
# Sources .env file if it exists, otherwise provides setup instructions
#
# Usage:
#   source scripts/setup_local_env.sh
#   fastlane release
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from .env file..."
  # Export variables from .env file
  set -a
  source "$ENV_FILE"
  set +a
  echo "✅ Environment variables loaded"
else
  echo "⚠️  .env file not found at $ENV_FILE"
  echo ""
  echo "To set up local Fastlane authentication:"
  echo "1. Copy .env.example to .env:"
  echo "   cp .env.example .env"
  echo ""
  echo "2. Edit .env and add your App Store Connect API credentials:"
  echo "   - APP_STORE_CONNECT_API_KEY_ID"
  echo "   - APP_STORE_CONNECT_ISSUER_ID"
  echo "   - APP_STORE_CONNECT_API_KEY_CONTENT (full .p8 file content)"
  echo ""
  echo "3. Optionally add OPENAI_API_KEY for AI-generated release notes"
  echo ""
  echo "4. Source this script again:"
  echo "   source scripts/setup_local_env.sh"
  echo ""
  echo "Note: .env is gitignored and will not be committed to the repository"
  exit 1
fi

