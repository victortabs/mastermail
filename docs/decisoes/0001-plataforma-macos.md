# 0001 — Primeira versão só para macOS

- **Data:** 2026-10-13
- **Status:** aceita

## Contexto
O fim do EWS (bloqueio a partir de 1º/10/2026, sem exceções após 1º/04/2027) deixa o Mail do Mac sem acesso ao Microsoft 365. iPhone e iPad escapam porque usam ActiveSync.

## Opções consideradas
1. Só macOS.
2. macOS + iOS/iPadOS.

## Decisão
Só macOS na primeira versão.

## Consequências
- Foco na dor real e no prazo; sem relay de push obrigatório (no Mac dá para fazer polling do delta com o app aberto).
- iOS fica para depois; manter o núcleo (sync, cache, IA) separado da UI para reaproveitar.
