<!-- PHP code to establish connection with the localserver -->
<?php

// Username is root
$user = 'root';
$password = 'Qwerty@1234';

// Database name is geeksforgeeks
$database = 'mysql';

// Server is localhost with
// port number 3306
$servername='localhost';
$mysqli = new mysqli($servername, $user,
				$password, $database);

// Checking for connections
if ($mysqli->connect_error) {
	die('Connect Error (' .
	$mysqli->connect_errno . ') '.
	$mysqli->connect_error);
}

// SQL query to select data from database
$sql = " SELECT user, authentication_string, plugin, host FROM mysql.user ";
$result = $mysqli->query($sql);
$mysqli->close();
?>
<!-- HTML code to display data in tabular format -->
<!DOCTYPE html>
<html lang="en">

<head>
	<meta charset="UTF-8">
	<title>MySQL User Details</title>
	<!-- CSS FOR STYLING THE PAGE -->
	<style>
		table {
			margin: 0 auto;
			font-size: large;
			border: 1px solid black;
		}

		h1 {
			text-align: center;
			color: #006600;
			font-size: xx-large;
			font-family: 'Gill Sans', 'Gill Sans MT',
			' Calibri', 'Trebuchet MS', 'sans-serif';
		}

		td {
			background-color: #E4F5D4;
			border: 1px solid black;
		}

		th,
		td {
			font-weight: bold;
			border: 1px solid black;
			padding: 10px;
			text-align: center;
		}

		td {
			font-weight: lighter;
		}
	</style>
</head>

<body>
	<section>
		<h1>Dynamic Demo</h1>
		<!-- TABLE CONSTRUCTION -->
		<table>
			<tr>
				<th>User</th>
				<th>Auth String</th>
				<th>Plugin</th>
				<th>Host</th>
			</tr>
			<!-- PHP CODE TO FETCH DATA FROM ROWS -->
			<?php 
				// LOOP TILL END OF DATA
				while($rows=$result->fetch_assoc())
				{
			?>
			<tr>
				<!-- FETCHING DATA FROM EACH
					ROW OF EVERY COLUMN -->
				<td><?php echo $rows['user'];?></td>
				<td><?php echo $rows['authentication_string'];?></td>
				<td><?php echo $rows['plugin'];?></td>
				<td><?php echo $rows['host'];?></td>
			</tr>
			<?php
				}
			?>
		</table>
	</section>
</body>

</html>
