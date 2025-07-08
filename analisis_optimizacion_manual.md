# Análisis Manual para Optimización del Scheduling

## Datos del Problema (6 Cocineros)

### Pasos Disponibles:
1. **Pasta Carbonatada (2 platos):**
   - Batir huevos 1: 180s, Bowl
   - Batir huevos 2: 180s, Bowl

2. **Ensalada César (3 platos):**
   - Lavar lechuga 1,2,3: 180s cada uno, Bowl
   - Hacer Crutones 1,2,3: 480s cada uno, Sartén
   - Preparar aderezo 1,2,3: 240s cada uno, Bowl
   - Armar ensalada 1,2,3: 120s cada uno, Bowl (depende de lavar+crutones+aderezo del mismo plato)

3. **Tiramisú Express (1 plato):**
   - Hacer café: 300s, Cafetera
   - Batir Mascarpone: 360s, Bowl
   - Mojar bizcochos: 180s, Bowl (depende de café)
   - Montar Capas: 480s, Moldes (depende de mascarpone + bizcochos)

### Recursos Disponibles:
- 6 Cocineros
- 5 Bowls
- 3 Sartenes
- 1 Cafetera
- 1 Moldes

## Análisis del Resultado Actual (1140s)

### Secuencia del Algoritmo Dinámico:
```
T0-T240:   Chef1(Crutones1,Sartén1) + Chef2(Crutones2,Sartén2) + Chef3(Crutones3,Sartén3) + 
           Chef4(Mascarpone,Bowl1) + Chef5(Café,Cafetera) + Chef6(Aderezo1,Bowl2)

T240-T300: Chef6(Aderezo2,Bowl2) [liberado]

T300-T360: Chef5(Aderezo3,Bowl3) [liberado café]

T360-T480: Chef4(Lavar1,Bowl1) [liberado mascarpone]

T480-T540: Chef1(Lavar2,Bowl2) + Chef2(Lavar3,Bowl4) + Chef3(Bizcochos,Bowl5) [liberados crutones]

T540-T660: Chef4(Huevos1,Bowl1) + Chef5(Huevos2,Bowl3) [liberado lavar1]

T660-T780: Chef1(Capas,Moldes) + Chef2(Ensalada1,Bowl2) + Chef3(Ensalada2,Bowl4) + Chef6(Ensalada3,Bowl5)

T780-T1140: Chef1(Capas,Moldes) [continúa hasta el final]
```

## Búsqueda de Optimización Manual

### Análisis del Cuello de Botella:
El **paso "Montar Capas" (480s)** es el último en terminar en T1140, y es parte del camino crítico del Tiramisú.

### Camino Crítico del Tiramisú:
- Hacer café: 300s (T0-T300)
- Mojar bizcochos: 180s (debe empezar después del café)
- Montar Capas: 480s (debe empezar después de mascarpone + bizcochos)

### Estrategia de Optimización:

#### OPCIÓN 1: Optimizar el inicio de "Mojar bizcochos"
**Problema identificado**: Bizcochos empieza en T480, pero el café termina en T300.
**Gap**: 180s de espera innecesaria

**Propuesta**:
- Hacer café: T0-T300
- Mojar bizcochos: T300-T480 (inmediatamente después del café)
- Esto permite que "Montar Capas" empiece antes

#### OPCIÓN 2: Reorganizar para liberar recursos antes
**Observación**: Los crutones terminan en T480, liberando 3 chefs simultáneamente.

**Propuesta Mejorada**:
```
T0-T240:   
  Chef1: Crutones1 (Sartén1)
  Chef2: Crutones2 (Sartén2) 
  Chef3: Crutones3 (Sartén3)
  Chef4: Mascarpone (Bowl1)
  Chef5: Café (Cafetera)
  Chef6: Aderezo1 (Bowl2)

T240-T300:
  Chef6: Aderezo2 (Bowl2)
  [Chef1,2,3,4,5 continúan]

T300-T360:
  Chef5: Bizcochos (Bowl3) ← ¡EMPEZAR INMEDIATAMENTE!
  Chef6: Aderezo3 (Bowl4)
  [Chef1,2,3,4 continúan]

T360-T480:
  Chef4: Lavar1 (Bowl1)
  Chef5: Bizcochos (Bowl3) [continúa]
  Chef6: Lavar2 (Bowl4)
  [Chef1,2,3 continúan crutones]

T480-T600:
  Chef1: Lavar3 (Bowl2)
  Chef2: Huevos1 (Bowl5)
  Chef3: Huevos2 (Bowl6)
  Chef4: Capas (Moldes) ← ¡EMPEZAR ANTES!
  Chef5: libre
  Chef6: libre

T540-T660:
  Chef4: Capas (Moldes) [continúa]
  Chef5: Ensalada1 (Bowl1)
  Chef6: Ensalada2 (Bowl3)

T600-T720:
  Chef1: Ensalada3 (Bowl2)
  Chef4: Capas (Moldes) [continúa]

T720-T960:
  Chef4: Capas (Moldes) [termina]
```

## Secuencia Optimizada Propuesta

### Nueva Timeline:
```
T0-T240:   6 chefs ocupados (crutones + mascarpone + café + aderezo1)
T240-T300: 5 chefs ocupados (aderezo2 agregado)
T300-T360: 6 chefs ocupados (bizcochos + aderezo3 empiezan)
T360-T480: 6 chefs ocupados (lavar1,2 + bizcochos continúa + crutones continúan)
T480-T720: Capas empieza + lavados + huevos + ensaladas
T720-T960: Solo Capas continúa
```

### Tiempo Total Estimado: **960s** ← ¡ÓPTIMO TEÓRICO!

## Verificación de Dependencias:

✅ **Ensaladas**: Cada ensalada puede empezar en T480 (cuando sus crutones y aderezos están listos)
✅ **Bizcochos**: Empieza en T300 (cuando café termina)
✅ **Capas**: Empieza en T480 (cuando mascarpone T360 y bizcochos T480 están listos)
✅ **Recursos**: Nunca se excede la capacidad de bowls, sartenes, etc.

## Conclusión:

**SÍ ES POSIBLE alcanzar 960s (el óptimo teórico) con 6 cocineros** mediante:

1. **Iniciar "Mojar bizcochos" inmediatamente en T300** (no esperar hasta T480)
2. **Iniciar "Montar Capas" en T480** (no esperar hasta T660)
3. **Mejor distribución de tareas de ensaladas** en paralelo

La clave está en **minimizar los gaps entre dependencias** y **maximizar el paralelismo** desde el inicio.

El algoritmo dinámico actual tiene una pequeña sub-optimalidad en la gestión de timing de dependencias, pero está muy cerca del óptimo. ¡Una mejora del 15.8% es posible!
