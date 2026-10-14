
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import 'detalhes.dart';
import 'formulario.dart';
import 'style/colors.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<dynamic> receitas = [];
  List<String> favoritas = [];

  bool carregando = true;
  bool erro = false;
  bool mostrarFavoritas = false;

  String pesquisa = '';
  String tipoSelecionado = 'TODAS';

  @override
  void initState() {
    super.initState();
    carregarDados();
    carregarFavoritas();
  }

  Future<void> carregarDados() async {
    setState(() {
      carregando = true;
      erro = false;
    });

    try {
      final resposta = await http.get(
        Uri.parse(Api.getEndPoint('receitas')),
      );

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);

        setState(() {
          if (dados is List) {
            receitas = dados;
          } else if (dados is Map && dados['receitas'] is List) {
            receitas = dados['receitas'];
          } else {
            receitas = [];
          }

          carregando = false;
        });
      } else {
        setState(() {
          erro = true;
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        erro = true;
        carregando = false;
      });
    }
  }

  Future<void> carregarFavoritas() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      favoritas = prefs.getStringList('favoritas') ?? [];
    });
  }

  Future<void> alterarFavorita(String id) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (favoritas.contains(id)) {
        favoritas.remove(id);
      } else {
        favoritas.add(id);
      }
    });

    await prefs.setStringList('favoritas', favoritas);
  }

  Future<void> abrirFormulario() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const Formulario(),
      ),
    );

    if (resultado == true) {
      carregarDados();
    }
  }

  Future<void> abrirDetalhes(Map<String, dynamic> receita) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => Detalhes(receita: receita),
      ),
    );

    if (resultado == true) {
      carregarDados();
    }
  }

  List<dynamic> get receitasFiltradas {
    return receitas.where((receita) {
      final nome = receita['nome']?.toString().toLowerCase() ?? '';
      final tipo = receita['tipo']?.toString().toUpperCase() ?? '';
      final id = receita['id']?.toString() ?? '';

      final combinaPesquisa = nome.contains(pesquisa.toLowerCase());

      final combinaTipo = tipoSelecionado == 'TODAS' ||
          tipo == tipoSelecionado;

      final combinaFavoritas =
          !mostrarFavoritas || favoritas.contains(id);

      return combinaPesquisa && combinaTipo && combinaFavoritas;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = receitasFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Livro de Receitas'),
        actions: [
          IconButton(
            tooltip: 'Mostrar favoritas',
            onPressed: () {
              setState(() {
                mostrarFavoritas = !mostrarFavoritas;
              });
            },
            icon: Icon(
              mostrarFavoritas ? Icons.favorite : Icons.favorite_border,
            ),
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar receita...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (valor) {
                setState(() {
                  pesquisa = valor;
                });
              },
            ),
          ),

          SizedBox(
            height: 55,
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

          Expanded(
            child: carregando
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : erro
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.wifi_off,
                                size: 55,
                                color: AppColors.c2,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Não foi possível carregar as receitas.',
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
                      )
                    : lista.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                mostrarFavoritas
                                    ? 'Você ainda não tem receitas favoritas.'
                                    : 'Nenhuma receita encontrada.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: carregarDados,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                90,
                              ),
                              itemCount: lista.length,
                              itemBuilder: (context, index) {
                                final receita =
                                    Map<String, dynamic>.from(lista[index]);

                                final nome =
                                    receita['nome']?.toString() ?? 'Receita';
                                final tipo =
                                    receita['tipo']?.toString() ?? '';
                                final imagem =
                                    receita['img']?.toString();
                                final id =
                                    receita['id']?.toString() ?? '';

                                final favorita = favoritas.contains(id);

                                return Card(
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => abrirDetalhes(receita),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (imagem != null &&
                                            imagem.trim().isNotEmpty)
                                          Image.network(
                                            imagem,
                                            width: double.infinity,
                                            height: 170,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return imagemIndisponivel();
                                            },
                                          )
                                        else
                                          imagemIndisponivel(),

                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            12,
                                            8,
                                            12,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
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
                                                    Chip(
                                                      label: Text(tipo),
                                                      avatar: const Icon(
                                                        Icons.restaurant_menu,
                                                        size: 18,
                                                      ),
                                                      backgroundColor:
                                                          AppColors.c4
                                                              .withValues(
                                                        alpha: 0.25,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: favorita
                                                    ? 'Remover dos favoritos'
                                                    : 'Adicionar aos favoritos',
                                                onPressed: () {
                                                  alterarFavorita(id);
                                                },
                                                icon: Icon(
                                                  favorita
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: favorita
                                                      ? Colors.red
                                                      : AppColors.c1,
                                                  size: 28,
                                                ),
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
                          ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: abrirFormulario,
        tooltip: 'Adicionar receita',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget filtroTipo(String tipo, String texto) {
    final selecionado = tipoSelecionado == tipo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        label: Text(texto),
        selected: selecionado,
        selectedColor: AppColors.c1,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selecionado ? Colors.white : AppColors.c1,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (selecionado) {
          setState(() {
            tipoSelecionado = tipo;
          });
        },
      ),
    );
  }

  Widget imagemIndisponivel() {
    return Container(
      width: double.infinity,
      height: 170,
      color: AppColors.c4.withValues(alpha: 0.25),
      child: const Icon(
        Icons.restaurant,
        size: 60,
        color: AppColors.c2,
      ),
    );
  }
}
