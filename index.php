<html>
<head>
  <title> Cloudron LAMP app </title>

  <style>

    body {
      width: 50%;
      min-width: 640px;
      margin: auto;
      font-family: Helvetica;
      color: #333;
    }

    pre {
      font-family: monospace;
      background: #333;
      color: white;
      border: none;
      width: 99%;
      padding: 10px;
      text-align: left;
      font-size: 13px;
      border-radius: 5px;
      margin-bottom: 15px;
      box-shadow: 0px 1px 12px rgba(0, 0, 0, 0.176);
    }

    h1 {
      text-align: center;
    }

    .center > table {
      width: 100%;
    }

    .h, .e {
      background-color: white !important;
    }

  </style>

</head>
<body>

<h1>Cloudron LAMP App</h1>

<br/>

<h2>SFTP Transfer</h2>
<p>
  You can SFTP files to the <b>public</b> folder using  <a href="https://cyberduck.io/" target="_blank">Cyberduck</a>,
  <a href="https://filezilla-project.org/" target="_blank">FileZilla</a> or <a href="https://www.gftp.org/" target="_blank">gFTP</a>
  (use your cloudron credentials to authenticate).
</p>
<p>
  We recommend disabling SFTP access (from Cloudron's configuration panel) once you have uploaded your code.
</p>
<pre>
sftp -P 2222 surfer.nebulon.info:public/
</pre>

<br/>

<h2>MySQL Credentials</h2>
<p>Use the following environment variables in the PHP code to access MySQL:</p>
<table>
  <tr>
    <td>MYSQL_HOST</td>
    <td><?php echo getenv("MYSQL_HOST") ?></td>
  </tr>
  <tr>
    <td>MYSQL_PORT</td>
    <td><?php echo getenv("MYSQL_PORT") ?></td>
  </tr>
  <tr>
    <td>MYSQL_USERNAME</td>
    <td><?php echo getenv("MYSQL_USERNAME") ?></td>
  </tr>
  <tr>
    <td>MYSQL_PASSWORD</td>
    <td><?php echo getenv("MYSQL_PASSWORD") ?></td>
  </tr>
  <tr>
    <td>MYSQL_DATABASE</td>
    <td><?php echo getenv("MYSQL_DATABASE") ?></td>
  </tr>
</table>

<br/>

<h2>phpMyAdmin Access</h2>
<p>
  You can access phpMyAdmin using your Cloudron credentials <a href="/phpmyadmin" target="_blank">here</a>.
</p>
<p>
  Note that disabling SFTP access also disables phpMyAdmin.
</p>

<br/>

<h2>Cron</h2>
<p>
  Put a file called <code>crontab</code> into the directory <code>/app/data</code> and it will picked up at next app restart.
  It has to be in the cron syntax without username and must end with a newline.
  For example, the following crontab updates feeds every hour:
</p>
<pre>
0 * * * * php /app/code/update.php --feeds
</pre>
<p>
  Commands are executed as the user www-data. Generate cron patterns via <a href="http://www.crontabgenerator.com/">crontabgenerator</a>.
</p>

<br/>

<h2>Sendmail Credentials</h2>
<p>Use the following environment variables in the PHP code to send email:</p>
<table>
  <tr>
    <td>MAIL_SMTP_SERVER</td>
    <td><?php echo getenv("MAIL_SMTP_SERVER") ?></td>
  </tr>
  <tr>
    <td>MAIL_SMTP_PORT</td>
    <td><?php echo getenv("MAIL_SMTP_PORT") ?></td>
  </tr>
  <tr>
    <td>MAIL_SMTPS_PORT</td>
    <td><?php echo getenv("MAIL_SMTPS_PORT") ?></td>
  </tr>
  <tr>
    <td>MAIL_SMTP_USERNAME</td>
    <td><?php echo getenv("MAIL_SMTP_USERNAME") ?></td>
  </tr>
  <tr>
    <td>MAIL_SMTP_PASSWORD</td>
    <td><?php echo getenv("MAIL_SMTP_PASSWORD") ?></td>
  </tr>
  <tr>
    <td>MAIL_FROM</td>
    <td><?php echo getenv("MAIL_FROM") ?></td>
  </tr>
  <tr>
    <td>MAIL_DOMAIN</td>
    <td><?php echo getenv("MAIL_DOMAIN") ?></td>
  </tr>
</table>

<br/>

<h2>Redis Credentials</h2>
<p>Use the following environment variables in the PHP code to connect to Redis:</p>
<table>
  <tr>
    <td>REDIS_URL</td>
    <td><?php echo getenv("REDIS_URL") ?></td>
  </tr>
  <tr>
    <td>REDIS_HOST</td>
    <td><?php echo getenv("REDIS_HOST") ?></td>
  </tr>
  <tr>
    <td>REDIS_PORT</td>
    <td><?php echo getenv("REDIS_PORT") ?></td>
  </tr>
  <tr>
    <td>REDIS_PASSWORD</td>
    <td><?php echo getenv("REDIS_PASSWORD") ?></td>
  </tr>
</table>

<br/>

<h2>Addons</h2>
<p>The app is configured to have access to the following Cloudron addons:</p>
<ul>
  <li><a href="https://cloudron.io/developer/addons/#mysql" target="_blank">mysql</a></li>
  <li><a href="https://cloudron.io/developer/addons/#localstorage" target="_blank">localstorage</a></li>
  <li><a href="https://cloudron.io/developer/addons/#sendmail" target="_blank">sendmail</a></li>
  <li><a href="https://cloudron.io/developer/addons/#redis" target="_blank">redis</a></li>
  <li><a href="https://cloudron.io/developer/addons/#ldap" target="_blank">ldap</a></li>
</ul>
<p>Read more about Cloudron addons and how to use them <a href="https://cloudron.io/developer/addons/" target="_blank">here</a>.</p>

<br/>

<h2>PHP Setup</h2>
<?php

echo phpInfo();

?>

</body>
</html>
