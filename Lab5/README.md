2 parts (original repos)
1st -> https://github.com/eyp/federated-learning-network
2nd -> https://github.com/imfing/keras-flask-deploy-webapp

PTI lab repos
1st -> https://repo.fib.upc.es/felix.freitag/pti/-/tree/master/ml_application/federated-learning-network-main
2nd -> https://repo.fib.upc.es/felix.freitag/pti/-/tree/master/ml_application/keras-flask-deploy-webapp-class_pneu

Deeper look (theoretical, Part I) -> [bandwidth_analysis.txt](bandwidth_analysis.txt)
Analysis of the network traffic of the federated training:
- Each round moves 2·N·S bytes: the whole model goes down to every client and comes back up.
- The model has 420,802 params (95% in the Dense layer after Flatten). Sent as JSON it takes 10.07 MB per transfer, 6x more than raw float32.
- Epochs and batch size don't change the bytes per round, only how much learning each round buys. With the default config (2 epochs x 10 steps x 5 images), each image seen costs about 201 KB of traffic.
- Federated learning gives privacy, not bandwidth savings: after about 21 rounds it has moved more data than uploading the raw dataset would.
- Proposed reductions: binary encoding, gzip, float16, GlobalAveragePooling. Combined they cut each transfer by about 250x.