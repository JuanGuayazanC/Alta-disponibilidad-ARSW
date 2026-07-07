#!/bin/bash
dnf update -y
dnf install -y httpd

systemctl enable httpd
systemctl start httpd

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
-H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
http://169.254.169.254/latest/meta-data/instance-id)

AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>Alta Disponibilidad - Instancia A</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f4f7fb;
      color: #1f2937;
      padding: 40px;
    }
    .card {
      background: white;
      border-radius: 12px;
      padding: 30px;
      max-width: 700px;
      margin: auto;
      box-shadow: 0 10px 25px rgba(0,0,0,0.08);
    }
    h1 {
      color: #2563eb;
    }
    .badge {
      display: inline-block;
      background: #dbeafe;
      color: #1d4ed8;
      padding: 6px 12px;
      border-radius: 20px;
      font-weight: bold;
    }
    code {
      background: #f3f4f6;
      padding: 4px 8px;
      border-radius: 6px;
    }
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">Instancia A</span>
    <h1>Aplicación Web en Alta Disponibilidad</h1>
    <p>Esta respuesta fue generada por la instancia A.</p>
    <p><strong>Instance ID:</strong> <code>$INSTANCE_ID</code></p>
    <p><strong>Availability Zone:</strong> <code>$AZ</code></p>
    <p><strong>Estado:</strong> Servicio disponible</p>
  </div>
</body>
</html>
EOF

echo "OK" > /var/www/html/health
