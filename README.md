# Alta Disponibilidad con Application Load Balancer en AWS

Laboratorio de la asignatura **Arquitecturas de Software** — implementación de una
arquitectura básica de alta disponibilidad en AWS Academy Learner Lab usando dos
instancias EC2 en zonas de disponibilidad distintas, un Target Group con health
checks y un Application Load Balancer.

## Estructura del repositorio

```
/README.md            Teoría, bitácora de ejecución, respuestas a las actividades
/scripts/              Scripts de User Data (provistos por la guía) para cada instancia EC2
/evidencias/           Capturas de pantalla del laboratorio (Reto final)
```

Este laboratorio no se organiza en ejercicios independientes: es un solo flujo de
trabajo continuo (Security Groups → EC2 → Target Group → ALB → pruebas → simulación
de falla → limpieza), por lo que toda la documentación vive en este único README.

## 1. Conceptos base

### 1.1 Alta disponibilidad

Es la capacidad de un sistema para mantenerse operativo aunque alguno de sus
componentes falle. Un sistema de instancia única tiene un punto único de falla
(*single point of failure*): si el servidor cae, el sistema completo queda
indisponible.

```
Sin redundancia:          Con redundancia:
Usuario                   Usuario
  ↓                         ↓
Servidor único            Balanceador de carga
                            ↓         ↓
                        Servidor A  Servidor B
```

Si el Servidor A falla, el balanceador redirige el tráfico al Servidor B.

### 1.2 Disponibilidad vs. escalabilidad

- **Disponibilidad**: ¿el sistema sigue funcionando si algo falla?
- **Escalabilidad**: ¿el sistema puede atender más carga si aumenta la demanda?

Son atributos de calidad independientes: una arquitectura puede escalar pero no ser
altamente disponible (todo en una sola zona de disponibilidad), o ser altamente
disponible pero no escalar automáticamente (sin Auto Scaling). Este laboratorio se
enfoca en **alta disponibilidad con balanceo de carga**, no en escalabilidad.

### 1.3 Application Load Balancer (ALB)

Recibe las solicitudes de los usuarios (HTTP/HTTPS) y las distribuye entre varios
servidores backend. Monitorea el estado de esos servidores mediante *health checks*
y solo les envía tráfico si están saludables.

### 1.4 Target Group

Conjunto de destinos (en este laboratorio, instancias EC2) a los que el ALB envía
tráfico, registrados con un protocolo y puerto específicos.

```
Target Group: tg-ha-web
 ├── EC2 instancia A (AZ 1)
 └── EC2 instancia B (AZ 2)
```

### 1.5 Health Check

Verificación periódica (ej. `GET /health`) que el ALB hace a cada target para saber
si puede recibir tráfico. Si el target no responde correctamente, se marca
*Unhealthy* y el balanceador deja de enviarle tráfico hasta que vuelva a responder.

## 2. Arquitectura objetivo

```
Usuario / Navegador / curl
            ↓
Application Load Balancer (DNS público)
     ↓                    ↓
EC2 Web A (AZ 1)     EC2 Web B (AZ 2)
Apache HTTPD          Apache HTTPD
```

## 3. Bitácora de ejecución

> Esta sección se completa a medida que se avanza en el laboratorio.

### 3.1 Preparación inicial

- Región asignada: *pendiente*

### 3.2 Security Groups

*Pendiente*

### 3.3 Instancias EC2

*Pendiente*

### 3.4 Target Group

*Pendiente*

### 3.5 Application Load Balancer

*Pendiente*

## 4. Actividades de análisis

### Actividad 1: análisis del balanceo

*Pendiente*

### Actividad 2: análisis de falla

*Pendiente*

### Actividad 3: análisis de recuperación

*Pendiente*

### Actividad 4: propuesta de mejora hacia producción

*Pendiente*

## 5. Tabla de validación arquitectónica

| Elemento | Función en la arquitectura |
|---|---|
| EC2 instancia A | *Pendiente* |
| EC2 instancia B | *Pendiente* |
| Application Load Balancer | *Pendiente* |
| Target Group | *Pendiente* |
| Health Check | *Pendiente* |
| Security Group del ALB | *Pendiente* |
| Security Group de EC2 | *Pendiente* |
| Zonas de disponibilidad | *Pendiente* |

## 6. Cómo reproducir este laboratorio

1. Crear los Security Groups `sg-alb-ha` y `sg-ec2-ha` (ver sección 3.2).
2. Lanzar dos instancias EC2 (`web-ha-a`, `web-ha-b`) en zonas de disponibilidad
   distintas, usando los scripts de `scripts/user-data-web-ha-a.sh` y
   `scripts/user-data-web-ha-b.sh` como User Data.
3. Crear el Target Group `tg-ha-web` con health check en `/health` y registrar ambas
   instancias.
4. Crear el Application Load Balancer `alb-ha-web` apuntando al Target Group.
5. Verificar balanceo, simular falla de una instancia y validar recuperación.
6. Eliminar todos los recursos al finalizar (ver sección 7).

## 7. Limpieza de recursos

Al finalizar, eliminar en este orden: Application Load Balancer → Target Group →
Instancias EC2 → Security Groups. *Estado: pendiente.*
