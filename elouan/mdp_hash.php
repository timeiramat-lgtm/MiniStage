<?php
$mdp1 = "Mdp1234_";
$mdp2 = "Admin_12";
$hash1 = password_hash($mdp1, PASSWORD_BCRYPT);
$hash2 = password_hash($mdp2, PASSWORD_BCRYPT);
echo "hash1 : ". $hash1."\nhash2 : ".$hash2."\n"
?>
