
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import 'detalhes.dart';
import 'style/colors.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> receitas = [];
  Set<int> favoritas = {};
  bool carregando = true;
  String erro = '';
  String pesquisa = '';
  String tipoSelecionado = 'TODAS';
  bool mostrarFavoritas = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() {
      carregando = true;
      erro = '';
    });

    try {
      final resposta = await http
          .get(Uri.parse(Api.getEndPoint('receitas')))
          .timeout(const Duration(seconds: 20));

      if (resposta.statusCode != 200) {
        throw Exception('Não foi possível carregar as receitas.');
      }

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! List) {
        throw Exception('A resposta da API está em um formato inesperado.');
      }

      final preferencias = await SharedPreferences.getInstance();
      final idsSalvos = preferencias.getStringList('receitas_favoritas') ?? [];

      if (!mounted) return;

      setState(() {
        receitas = dados
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        favoritas = idsSalvos
            .map((id) => int.tryParse(id))
            .whereType<int>()
            .toSet();

        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = 'Não foi possível carregar as receitas. '
            'Verifique sua conexão e tente novamente.';
      });
    }
  }

  Future<void> alternarFavorita(int id) async {
    final preferencias = await SharedPreferences.getInstance();

    setState(() {
      if (favoritas.contains(id)) {
        favoritas.remove(id);
      } else {
        favoritas.add(id);
      }
    });

    await preferencias.setStringList(
      'receitas_favoritas',
      favoritas.map((id) => id.toString()).toList(),
    );
  }

  List<Map<String, dynamic>> get receitasFiltradas {
    return receitas.where((receita) {
      final nome = (receita['nome'] ?? '').toString().toLowerCase();
      final combinaPesquisa = nome.contains(pesquisa.toLowerCase());

      final tipo = (receita['tipo'] ?? '').toString().toUpperCase();
      final combinaTipo =
          tipoSelecionado == 'TODAS' || tipo == tipoSelecionado;

      final id = int.tryParse('${receita['id']}') ?? -1;
      final combinaFavorita =
          !mostrarFavoritas || favoritas.contains(id);

      return combinaPesquisa && combinaTipo && combinaFavorita;
    }).toList();
  }

  String nomeTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'DOCE':
        return 'Doces';
      case 'SALGADA':
        return 'Salgadas';
      case 'BEBIDA':
        return 'Bebidas';
      default:
        return tipo;
    }
  }

  Widget imagemReceita(String? url) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        color: AppColors.c4.withValues(alpha: 0.25),
        child: const Center(
          child: Icon(
            Icons.restaurant,
            size: 48,
            color: AppColors.c2,
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.c4.withValues(alpha: 0.25),
          child: const Center(
            child: Icon(
              Icons.restaurant,
              size: 48,
              color: AppColors.c2,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = receitasFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Livro de Receitas'),
        actions: [
          IconButton(
            tooltip: 'Atualizar receitas',
            onPressed: carregarDados,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: TextField(
              onChanged: (valor) {
                setState(() {
                  pesquisa = valor;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar uma receita...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                filtroTipo('TODAS', 'Todas'),
                filtroTipo('DOCE', 'Doces'),
                filtroTipo('SALGADA', 'Salgadas'),
                filtroTipo('BEBIDA', 'Bebidas'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                selected: mostrarFavoritas,
                avatar: const Icon(Icons.favorite, size: 18),
                label: const Text('Somente favoritas'),
                onSelected: (valor) {
                  setState(() {
                    mostrarFavoritas = valor;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (carregando) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (erro.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            size: 48,
                            color: AppColors.c2,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            erro,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: carregarDados,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (lista.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma receita encontrada.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: carregarDados,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final receita = lista[index];
                      final id = int.tryParse('${receita['id']}') ?? -1;
                      final tipo = (receita['tipo'] ?? '').toString();
                      final imagem = receita['img']?.toString();
                      final nome =
                          receita['nome']?.toString() ?? 'Sem nome';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Detalhes(
                                  receita: receita,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 190,
                                width: double.infinity,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    imagemReceita(imagem),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: IconButton(
                                          tooltip: 'Favoritar',
                                          onPressed: () =>
                                              alternarFavorita(id),
                                          icon: Icon(
                                            favoritas.contains(id)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: favoritas.contains(id)
                                                ? Colors.red
                                                : AppColors.c1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nome,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.restaurant_menu,
                                          size: 17,
                                          color: AppColors.c2,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(nomeTipo(tipo)),
                                        const Spacer(),
                                        const Text(
                                          'Ver receita  →',
                                          style: TextStyle(
                                            color: AppColors.c1,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget filtroTipo(String valor, String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(titulo),
        selected: tipoSelecionado == valor,
        onSelected: (selecionado) {
          setState(() {
            tipoSelecionado = valor;
          });
        },
      ),
    );
  }
}
