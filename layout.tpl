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
		{{!base}}
	</body>
</html>