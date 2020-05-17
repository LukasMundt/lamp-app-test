<html>
<head>
  <title> Cloudron LAMP app (PHP 7.3)</title>

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

    .table {
      border-style: solid;
      border-width: 1px;
    }

    .h, .e {
      background-color: white !important;
    }

  </style>

</head>
<body>

<br/>

<h1>Cloudron LAMP App (PHP 7.3)</h1>

<br/>

<h2>Overview</h2>
<p>
  <div>
  This page is a placeholder showing information on how to use the LAMP stack (PHP <?php echo PHP_VERSION ?>)
  This page will get overwritten, when an index.php or index.html is uploaded. You can always
  access the database credentials from the file <code>credentials.txt</code> with <a target="_blank" href="https://cloudron.io/documentation/apps/#ftp-access">SFTP</a>.
  <div>
  <br/>
  <b>The credentials shown here can only be used from within your app. They will not work from outside the Cloudron.</b>
</p>

<br/>

<h2>MySQL Credentials</h2>
<p>Use the following environment variables in the PHP code to access MySQL:</p>
<table>
  <tr>
    <td>CLOUDRON_MYSQL_HOST</td>
    <td><?php echo getenv("CLOUDRON_MYSQL_HOST") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_MYSQL_PORT</td>
    <td><?php echo getenv("CLOUDRON_MYSQL_PORT") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_MYSQL_USERNAME</td>
    <td><?php echo getenv("CLOUDRON_MYSQL_USERNAME") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_MYSQL_PASSWORD</td>
    <td><?php echo getenv("CLOUDRON_MYSQL_PASSWORD") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_MYSQL_DATABASE</td>
    <td><?php echo getenv("CLOUDRON_MYSQL_DATABASE") ?></td>
  </tr>
</table>

<br/>

<h2>phpMyAdmin Access</h2>
<p>
  It is installed <a href="/phpmyadmin" target="_blank">here</a>. For login credentials see phpmyadmin_login.txt via SFTP.
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
    <td>CLOUDRON_MAIL_SMTP_SERVER</td>
    <td><?php echo getenv("CLOUDRON_MAIL_SMTP_SERVER") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_MAIL_SMTP_PORT</td>
    <td><?php echo getenv("CLOUDRON_MAIL_SMTP_PORT") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_MAIL_SMTPS_PORT</td>
    <td><?php echo getenv("CLOUDRON_MAIL_SMTPS_PORT") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_MAIL_SMTP_USERNAME</td>
    <td><?php echo getenv("CLOUDRON_MAIL_SMTP_USERNAME") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_MAIL_SMTP_PASSWORD</td>
    <td><?php echo getenv("CLOUDRON_MAIL_SMTP_PASSWORD") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_MAIL_FROM</td>
    <td><?php echo getenv("CLOUDRON_MAIL_FROM") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_MAIL_DOMAIN</td>
    <td><?php echo getenv("CLOUDRON_MAIL_DOMAIN") ?></td>
  </tr>
</table>

<br/>

<h2>Redis Credentials</h2>
<p>Use the following environment variables in the PHP code to connect to Redis:</p>
<table>
  <tr>
    <td>CLOUDRON_REDIS_URL</td>
    <td><?php echo getenv("CLOUDRON_REDIS_URL") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_REDIS_HOST</td>
    <td><?php echo getenv("CLOUDRON_REDIS_HOST") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_REDIS_PORT</td>
    <td><?php echo getenv("CLOUDRON_REDIS_PORT") ?></td>
  </tr>
  <tr>
    <td>CLOUDRON_REDIS_PASSWORD</td>
    <td><?php echo getenv("CLOUDRON_REDIS_PASSWORD") ?></td>
  </tr>
</table>

<br/>

</body>
</html>
