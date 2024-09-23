# Sergio Jump - Evita las bombas.

¡Bienvenido al repositorio de **Sergio Jump | Evita la bomba de la menena**!

## Mecánica del Juego

### Modos de Juego
- **Single Player**: Controla a un solo jugador y evita las bombas y misiles.
- **Co-op**: Juega con un amigo y cooperen para evitar las bombas y misiles.

### Controles
- **Jugador 1**:
  - Movimiento: Flechas izquierda y derecha
  - Saltar: Barra espaciadora
  - Empuje: Ctrl izquierdo
- **Jugador 2** (solo en modo Co-op):
  - Movimiento: Teclas 'A' y 'D'
  - Saltar: Tecla 'F'
  - Empuje: Tecla 'G'

### Objetivo
- Evita las bombas y misiles el mayor tiempo posible.
- Usa el empuje para desviar las bombas.
- Gana puntos por cada segundo que sobrevivas.
- En modo Co-op, gana rondas evitando las bombas más tiempo que tu compañero.

## Instalación

### Requisitos
- [LÖVE 2D](https://love2d.org/) (versión 11.3 o superior)

### Pasos para Instalar
1. Clona este repositorio en tu máquina local:
    ```sh
    git clone https://github.com/tu_usuario/juego-evitar-bombas.git
    ```
2. Navega al directorio del juego:
    ```sh
    cd juego-evitar-bombas
    ```
3. Ejecuta el juego con LÖVE:
    ```sh
    love .
    ```

## Código Principal


### `juego.lua`
Este archivo contiene la lógica del juego, incluyendo la actualización de los jugadores, las bombas, los misiles, y la detección de colisiones.

El código principal del juego se encuentra en `main.lua` y `juego.lua`. Aquí hay una breve descripción de los archivos más importantes:

### `main.lua`
Este archivo maneja la inicialización del juego, la carga de recursos, y la lógica principal del menú y los estados del juego.


### `jugador.lua`
Define la clase `Jugador` y maneja el movimiento, el salto y el empuje de los jugadores.


### `bomba.lua`
Define la clase `Bomba` y maneja su comportamiento, incluyendo la física y las colisiones.


### `misil.lua`
Define la clase `Misil` y maneja su comportamiento, incluyendo la física y las colisiones.


### `highscore.lua`
Maneja la carga y el guardado de la puntuación más alta.


### `utils.lua`
Contiene funciones utilitarias para cálculos de distancia y colisiones.


## Efectos Visuales

El juego utiliza la biblioteca `moonshine` para aplicar efectos visuales como CRT y scanlines. Puedes encontrar más información sobre cómo usar `moonshine` en su [README](https://github.com/vrld/moonshine).

## Contribuciones

¡Las contribuciones son bienvenidas! Si encuentras algún error o tienes alguna mejora, no dudes en abrir un issue o enviar un pull request.

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.
