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

- Región asignada: **us-east-1 (US East, N. Virginia)**

### 3.2 Security Groups

> **Nota — desviación respecto a la guía:** AWS no permite nombres de Security
> Group que empiecen con el prefijo `sg-`, porque ese prefijo lo reserva AWS para
> los IDs autogenerados (`sg-0123abcd...`). La guía nombra los grupos `sg-alb-ha`
> y `sg-ec2-ha`, pero la consola rechaza esos nombres. Se usan en su lugar:
>
> | Nombre en la guía | Nombre usado en este laboratorio |
> |---|---|
> | `sg-alb-ha` | `alb-ha-sg` |
> | `sg-ec2-ha` | `ec2-ha-sg` |
>
> El resto de la configuración (reglas de entrada/salida, descripciones) se
> mantiene igual a lo indicado en la guía.

VPC utilizada (VPC predeterminada): `vpc-03ea05e656470d33f`

| Security Group | ID | Regla de entrada | Regla de salida |
|---|---|---|---|
| `alb-ha-sg` | `sg-0808e0cd3ade56777` | HTTP (TCP 80) desde `0.0.0.0/0` | All traffic → `0.0.0.0/0` (default) |
| `ec2-ha-sg` | `sg-0d0cb03db103abeae` | HTTP (TCP 80) desde `alb-ha-sg` | All traffic → `0.0.0.0/0` (default) |

**Por qué `ec2-ha-sg` referencia a `alb-ha-sg` como origen (en vez de una IP):**
el ALB estará desplegado en dos zonas de disponibilidad, por lo que tiene más de
una IP y estas pueden cambiar. Referenciar el Security Group del ALB como origen
significa "acepta tráfico de cualquier recurso que tenga este Security Group
asociado", sin depender de direcciones IP concretas. Esto también aplica el
principio de menor privilegio: las instancias EC2 solo aceptan tráfico que pase
por el ALB, no tráfico directo desde cualquier IP de Internet.

### 3.3 Instancias EC2

| Instancia | ID | IP pública | Zona de disponibilidad | Security Group |
|---|---|---|---|---|
| `web-ha-a` | `i-06ae96e94534b8e60` | `32.192.25.11` | us-east-1a | `ec2-ha-sg` |
| `web-ha-b` | `i-0b722c2816698d4f5` | `32.192.69.248` | us-east-1f | `ec2-ha-sg` |

Ambas instancias tipo `t3.micro`, par de claves `ARSW` (RSA, `.pem`), sin perfil de
instancia de IAM, con IP pública habilitada, usando el User Data provisto por la
guía ([scripts/user-data-web-ha-a.sh](scripts/user-data-web-ha-a.sh) y
[scripts/user-data-web-ha-b.sh](scripts/user-data-web-ha-b.sh)).

**Verificación (punto 12 de la guía):**

| URL | Resultado |
|---|---|
| `http://32.192.25.11` | Tarjeta "Instancia A" con Instance ID y AZ correctos |
| `http://32.192.69.248` | Tarjeta "Instancia B" con Instance ID y AZ correctos |
| `http://32.192.25.11/health` | `OK` |
| `http://32.192.69.248/health` | `OK` |

> **Nota — inconsistencia detectada en la guía:** el punto 12 pide probar la IP
> pública de cada instancia *antes* de crear el Target Group y el ALB (puntos 13
> y 14). Sin embargo, la regla de `ec2-ha-sg` configurada en el punto 9 solo
> permite tráfico HTTP con origen el Security Group `alb-ha-sg`, que en este
> punto del laboratorio todavía no existe (el ALB no se ha creado). Como
> resultado, la prueba directa por navegador fallaba con
> `ERR_CONNECTION_TIMED_OUT` — lo cual en realidad es el comportamiento
> **correcto** del Security Group, no un error de configuración.
>
> **Solución aplicada:** se agregó temporalmente una segunda regla de entrada en
> `ec2-ha-sg` (HTTP, TCP 80, origen `0.0.0.0/0`, descrita como "TEMPORAL") solo
> para validar que Apache y `/health` respondían correctamente en cada
> instancia. Esa regla se elimina inmediatamente después de la verificación,
> dejando `ec2-ha-sg` únicamente con la regla de origen `alb-ha-sg` antes de
> continuar con el Target Group.

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
