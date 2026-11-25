== Busca híbrida

Com o $k = 10$ escolhido no dev, o híbrido supera o lexical e o semântico em todas as métricas (@tab-all-systems). O NDCG\@10 sobe 0,0316 sobre o lexical (+10,1%) e 0,0273 sobre o semântico (+8,6%), e o MAP\@10 sobe cerca de 13%, a um custo de 0,07 ms por consulta. O ganho vem da *complementaridade* entre os sistemas:

- em média, só 22 dos 100 primeiros documentos são comuns aos dois rankings;
- entre os 100 primeiros, o lexical traz 6,5 relevantes, o semântico 8,0 e a união dos dois 9,7;
- o RRF favorece o consenso: 6,5 dos 10 primeiros documentos do híbrido estão nos dois rankings.

Por consulta, o híbrido é melhor que os dois sistemas em 42 consultas, fica entre eles (ou igual a um deles) em 272 e é pior que ambos em 9. As consultas sem relevante no top-10 caem de 102 (lexical) e 100 (semântico) para 89. A fusão, porém, não identifica qual sistema está certo em cada consulta: escolher o melhor dos dois em cada uma daria NDCG\@10 de 0,3795. O RRF também cria empates, pois a posição $r$ só no lexical vale o mesmo que a posição $r$ só no semântico. Em 30 consultas há empate entre a 10ª e a 11ª posição, resolvido pelo identificador.
