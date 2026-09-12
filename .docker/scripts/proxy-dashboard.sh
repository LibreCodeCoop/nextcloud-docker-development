#!/bin/sh

set -eu

html_dir="${HTML_DIR:-/html}"
output="$html_dir/index.html"

html_escape() {
	printf '%s' "$1" |
		sed \
			-e 's/&/\&amp;/g' \
			-e 's/</\&lt;/g' \
			-e 's/>/\&gt;/g' \
			-e 's/"/\&quot;/g' \
			-e "s/'/\&#39;/g"
}

service_title() {
	case "$1" in
		nginx)
			printf 'Nextcloud'
			;;
		mailpit)
			printf 'Mailpit'
			;;
		playwright)
			printf 'Playwright'
			;;
		eurooffice)
			printf 'EuroOffice'
			;;
		signal-gateway)
			printf 'Signal Gateway'
			;;
		*)
			printf '%s' "$1"
			;;
	esac
}

active_hosts() {
	docker ps --filter network=librecode-dev-proxy --format '{{.ID}}' |
	while IFS= read -r container; do
		[ -n "$container" ] || continue

		virtual_hosts="$(docker inspect \
			--format '{{range .Config.Env}}{{println .}}{{end}}' \
			"$container" |
			sed -n 's/^VIRTUAL_HOST=//p' |
			head -n 1)"

		[ -n "$virtual_hosts" ] || continue

		project="$(docker inspect \
			--format '{{ index .Config.Labels "com.docker.compose.project" }}' \
			"$container" 2>/dev/null || true)"
		service="$(docker inspect \
			--format '{{ index .Config.Labels "com.docker.compose.service" }}' \
			"$container" 2>/dev/null || true)"

		[ -n "$project" ] || project="Docker"
		[ -n "$service" ] || service="Service"

		printf '%s\n' "$virtual_hosts" |
			tr ',' '\n' |
		while IFS= read -r host; do
			host="$(printf '%s' "$host" | tr -d '[:space:]')"
			case "$host" in
				*.localhost)
					printf '%s|%s|%s\n' "$project" "$service" "$host"
					;;
			esac
		done
	done |
		sort -u
}

generate_dashboard() {
	tmp="${output}.tmp"
	hosts_file="$(mktemp)"
	trap 'rm -f "$hosts_file" "$tmp"' EXIT INT TERM

	active_hosts > "$hosts_file"

	cat > "$tmp" <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>LibreCode Development Proxy</title>
  <style>
    :root { color-scheme: light dark; font-family: system-ui, sans-serif; }
    body { margin: 0; min-height: 100vh; display: grid; place-items: start center; background: Canvas; color: CanvasText; }
    main { width: min(760px, calc(100% - 48px)); margin: 26px 0; padding: 32px; border: 1px solid color-mix(in srgb, CanvasText 20%, transparent); border-radius: 12px; }
    h1 { margin-top: 0; font-size: 1.5rem; }
    h2 { margin-top: 2rem; font-size: 1.15rem; }
    h3 { margin: 1.5rem 0 .5rem; font-size: 1rem; }
    ul { padding-left: 1.25rem; }
    li { margin: .45rem 0; }
    a { color: LinkText; }
    code { padding: .15em .4em; border-radius: 4px; background: color-mix(in srgb, CanvasText 10%, transparent); }
    .not-found { padding: 1rem; border: 1px solid color-mix(in srgb, CanvasText 24%, transparent); border-radius: 8px; }
    .muted { opacity: .7; }
  </style>
</head>
<body>
  <main>
    <h1>💙 LibreCode Development Proxy</h1>
    <section id="not-found" class="not-found" hidden>
      <h2>Environment not found</h2>
      <p>There is no active development service for <code id="requested-host"></code>.</p>
      <p id="suggestion" hidden>Did you mean <a id="suggestion-link"></a>?</p>
    </section>
    <p>The shared development proxy is running.</p>
    <h2>Active environments</h2>
EOF

	if [ ! -s "$hosts_file" ]; then
		printf '    <p class="muted">No development environments are active.</p>\n' >> "$tmp"
	else
		current_project=""
		while IFS='|' read -r project service host; do
			project_html="$(html_escape "$project")"
			service_html="$(html_escape "$(service_title "$service")")"
			host_html="$(html_escape "$host")"

			if [ "$project" != "$current_project" ]; then
				if [ -n "$current_project" ]; then
					printf '    </ul>\n' >> "$tmp"
				fi
				printf '    <h3>%s</h3>\n    <ul>\n' "$project_html" >> "$tmp"
				current_project="$project"
			fi

			printf '      <li><strong>%s:</strong> <a data-host="%s" href="https://%s">https://%s</a></li>\n' \
				"$service_html" "$host_html" "$host_html" "$host_html" >> "$tmp"
		done < "$hosts_file"
		printf '    </ul>\n' >> "$tmp"
	fi

	cat >> "$tmp" <<'EOF'
    <p class="muted">This page is generated from the services currently connected to the shared development proxy.</p>
  </main>
  <script>
    const requestedHost = window.location.hostname;
    if (requestedHost !== 'localhost') {
      const panel = document.getElementById('not-found');
      document.getElementById('requested-host').textContent = requestedHost;
      panel.hidden = false;

      const hosts = [...document.querySelectorAll('[data-host]')].map((link) => link.dataset.host);
      const distance = (a, b) => {
        const row = Array.from({ length: b.length + 1 }, (_, index) => index);
        for (let i = 1; i <= a.length; i++) {
          let previous = row[0];
          row[0] = i;
          for (let j = 1; j <= b.length; j++) {
            const current = row[j];
            row[j] = Math.min(row[j] + 1, row[j - 1] + 1, previous + (a[i - 1] === b[j - 1] ? 0 : 1));
            previous = current;
          }
        }
        return row[b.length];
      };

      if (hosts.length > 0) {
        const closest = hosts.reduce((best, host) => distance(requestedHost, host) < distance(requestedHost, best) ? host : best);
        const suggestion = document.getElementById('suggestion');
        const link = document.getElementById('suggestion-link');
        link.href = `https://${closest}`;
        link.textContent = closest;
        suggestion.hidden = false;
      }
    }
  </script>
</body>
</html>
EOF

	mv "$tmp" "$output"
	rm -f "$hosts_file"
	trap - EXIT INT TERM
}

mkdir -p "$html_dir"
generate_dashboard

while true; do
	docker events \
		--filter type=container \
		--filter event=start \
		--filter event=stop \
		--filter event=die \
		--filter event=destroy \
		--format '{{.Status}}' |
	while IFS= read -r _event; do
		generate_dashboard
	done

	sleep 1
done
