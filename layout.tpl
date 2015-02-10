% from bottle import request
<!doctype html>
<html>
	<head>
		<link href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css" rel="stylesheet">
		<style>
			.multi-radio input {
				display: none;
			}
			.multi-radio label {
				display: none;
				cursor: pointer;
				-webkit-touch-callout: none;
				-webkit-user-select: none;
				-khtml-user-select: none;
				-moz-user-select: none;
				-ms-user-select: none;
				user-select: none;
			}
			.multi-radio label a {
				display: block;
			}
			.multi-radio input:checked + label {
				display: block;
			}

			.progress-multi .progress {
				margin: 0;
				border-radius: 0;
			}

			.progress-multi {
				margin-bottom: 10px;
			}
			.progress-multi .progress:first-child {
				border-top-left-radius: 4px;
				border-top-right-radius: 4px;
			}
			.progress-multi .progress:last-child {
				border-bottom-left-radius: 4px;
				border-bottom-right-radius: 4px;
			}
			.clip .inner {
				text-overflow: ellipsis;
				display: block;
				white-space: nowrap;
				overflow: hidden;
			}
			.clip .right {
				float: right;
				padding-top: 10px;
			}

			form {margin :0;}
		</style>
	</head>
	<body>
		<nav class="navbar navbar-default navbar-static-top">
			<%
			def cond(b):
				return True if b else None
			end
			def active_if(b, *rest):
				if b:
					rest = ('active',) + rest
				end
				if rest:
					return 'class="{}"'.format(' '.join(rest))
				end
			end
			%>
			<div class="container">
				<div class="navbar-header">
					<a class="navbar-brand" href="#">Example papers</a>
				</div>
				<div>
					<ul class="nav navbar-nav">
						<li {{!active_if(request.urlparts.path == '/') }}>
							<a href="/">List</a>
						</li>
						% is_graph = request.urlparts.path == '/graph'
						<li {{!active_if(is_graph, 'dropdown')}}>
							<a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false">Graph <span class="caret"></span></a>
							<ul class="dropdown-menu" role="menu">
								<li {{!active_if(is_graph and request.query.days == '0.041666')}}>
									<a href="/graph?days=0.041666">Last day</a></li>
								<li {{!active_if(is_graph and request.query.days == '1')}}>
									<a href="/graph?days=1">Last day</a></li>
								<li {{!active_if(is_graph and request.query.days == '2')}}>
									<a href="/graph?days=2">Last two days</a></li>
								<li {{!active_if(is_graph and request.query.days == '7')}}>
									<a href="/graph?days=7">Last week</a></li>
								<li {{!active_if(is_graph and request.query.days == '14')}}>
									<a href="/graph?days=14">Last two weeks</a></li>
							</ul>
						</li>
					</ul>
				</div>
			</div>
		</nav>
		{{!base}}
		<script src="https://code.jquery.com/jquery-2.1.3.min.js"></script>
		<script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
	</body>
</html>