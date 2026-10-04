#!/bin/sh
# SPDX-FileCopyrightText: 2026 LibreCode coop and contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

set -eu
cat "$(dirname "$0")/identity.txt" > /var/www/html/data/consumer-hook
