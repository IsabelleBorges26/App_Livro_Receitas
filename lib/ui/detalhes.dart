
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import 'formulario.dart';
import 'style/colors.dart';

class Detalhes extends StatelessWidget {
  final Map<String, dynamic> receita;

  const Detalhes({
    super.key,
    required this.receita,
  });

  Future<void> excluirReceita(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir receita'),
        content: const Text('Deseja realmente excluir esta receita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    try {
      final resposta = await http.delete(
        Uri.parse(Api.getEndPoint('receitas/${receita['id']}')),
      );

      if (!context.mounted) return;

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receita excluída!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível excluir. Erro ${resposta.statusCode}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão com a API.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = receita['nome']?.toString() ?? 'Receita';
    final tipo = receita['tipo']?.toString() ?? '';
    final ingredientes =
        receita['ingredientes']?.toString() ?? 'Não informado';
    final modoFazer =
        receita['modoFazer']?.toString() ?? 'Não informado';
    final imagem = receita['img']?.toString();
    final custo = receita['custoAproximado'];

    String? custoFormatado;

    if (custo is num) {
      custoFormatado = custo.toStringAsFixed(2).replaceAll('.', ',');
    } else if (custo != null) {
      final valor = double.tryParse(custo.toString());
      if (valor != null) {
        custoFormatado = valor.toStringAsFixed(2).replaceAll('.', ',');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(nome),
        actions: [
          IconButton(
            tooltip: 'Editar receita',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final resultado = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => Formulario(receita: receita),
                ),
              );

              if (resultado == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            tooltip: 'Excluir receita',
            icon: const Icon(Icons.delete),
            onPressed: () => excluirReceita(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagem != null && imagem.trim().isNotEmpty)
              Image.network(
                imagem,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return imagemIndisponivel();
                },
              )
            else
              imagemIndisponivel(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: const Icon(Icons.restaurant_menu),
                    label: Text(tipo),
                  ),
                  if (custoFormatado != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: AppColors.c1,
                        ),
                        const SizedBox(width: 8),
                        Text('Custo aproximado: R\$ $custoFormatado'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  tituloSecao('Ingredientes', Icons.shopping_basket),
                  const SizedBox(height: 10),
                  textoReceita(ingredientes),
                  const SizedBox(height: 28),
                  tituloSecao('Modo de preparo', Icons.menu_book),
                  const SizedBox(height: 10),
                  textoReceita(modoFazer),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar às receitas'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget imagemIndisponivel() {
    return Container(
      width: double.infinity,
      height: 220,
      color: AppColors.c4.withValues(alpha: 0.25),
      child: const Icon(
        Icons.restaurant,
        size: 70,
        color: AppColors.c2,
      ),
    );
  }

  Widget tituloSecao(String titulo, IconData icone) {
    return Row(
      children: [
        Icon(icone, color: AppColors.c1),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: AppColors.c1,
            fontFamily: 'PatrickHand',
          ),
        ),
      ],
    );
  }

  Widget textoReceita(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 17,
          height: 1.6,
          color: AppColors.c1,
          fontFamily: 'PatrickHand',
        ),
      ),
    );
  }
}
