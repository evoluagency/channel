# V-01B: executar somente em MUNDO NOVO E PLANO, com comandos ativados.
# Primeiro constroi a cidade, depois registra nascimento na praca.
execute positioned ~-48 ~ ~-48 run function valdora/construir
# Spawn seguro: entrada sul da praca, fora da fonte central.
setworldspawn ~-1 ~1 ~13
spawnpoint @s ~-1 ~1 ~13
tp @s ~-0.5 ~1 ~13.5