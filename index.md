<html>
<body>

<p>This chart is a thin wrapper around
[zero-to-jupyterhub](https://zero-to-jupyterhub.readthedocs.io/en/latest/) to
allow authentication with shibboleth for syzygy project JupyterHub instances.


Jump to:

<ul>
<li><a href="#development-releases-syzygy">Development Releases: Syzygy</a></li>
</ul>

<h2>Stable releases</h2>
{% assign syzygy = site.data.index.entries.one-two-syzygy | sort: 'created' | reverse %}
<table>
  <tr>
    <th>release</th>
    <th>date</th>
  </tr>
  {% for chart in syzygy %}
    {% unless chart.version contains "-"%}
    <tr>
      <td>
      <a href="{{ chart.urls[0] }}">
          {{ chart.name }}-{{ chart.version | remove_first: "v" }}
      </a>
      </td>
      <td>
      <span class='date'>{{ chart.created | date_to_rfc822 }}</span>
      </td>
    </tr>
    {% endunless %}
  {% endfor %}
</table>

<h2>Development releases: Syzygy</h2>
<table>
  <tr>
    <th>release</th>
    <th>date</th>
  </tr>
  {% for chart in syzygy %}
    <tr>
      <td>
      {% unless chart.version contains "-" %}<b>{% endunless %}
      <a href="{{ chart.urls[0] }}">
          {{ chart.name }}-{{ chart.version | remove_first: "v" }}
      </a>
      {% unless chart.version contains "-" %}</b>{% endunless %}
      </td>
      <td>
      <span class='date'>{{ chart.created | date_to_rfc822 }}</span>
      </td>
    </tr>
  {% endfor %}
</table>
</body>
</html>
