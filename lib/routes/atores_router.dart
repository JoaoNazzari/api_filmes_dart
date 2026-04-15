// lib/atores_router.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'ator_database.dart';
import 'database.dart';
import 'models/atores.dart';

Router atorRouter(AtorDatabaseHelper atorDb, DatabaseHelper filmeDb) {
  final router = Router();

  // GET /atores — Listar todos
  router.get('/atores', (Request request) async {
    final atores = await atorDb.getAll();
    return Response.ok(
      jsonEncode(atores.map((a) => a.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // GET /atores/<id> — Buscar por ID
  router.get('/atores/<id>', (Request request, String id) async {
    final atorId = int.tryParse(id);

    if (atorId == null) {
      return Response(400,
        body: jsonEncode({'erro': 'O ID precisa ser um número válido.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final ator = await atorDb.getById(atorId);

    if (ator == null) {
      return Response(404,
        body: jsonEncode({'erro': 'Ator com ID $atorId não encontrado.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode(ator.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // GET /filmes/<id>/atores — Listar atores de um filme
  router.get('/filmes/<id>/atores', (Request request, String id) async {
    final filmeId = int.tryParse(id);

    if (filmeId == null) {
      return Response(400,
        body: jsonEncode({'erro': 'O ID precisa ser um número válido.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final filme = await filmeDb.getById(filmeId);
    if (filme == null) {
      return Response(404,
        body: jsonEncode({'erro': 'Filme com ID $filmeId não encontrado.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final atores = await atorDb.getByFilmeId(filmeId);
    return Response.ok(
      jsonEncode(atores.map((a) => a.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // POST /atores — Criar novo ator
  router.post('/atores', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (data['nome'] == null || data['filmeId'] == null) {
        return Response(400,
          body: jsonEncode({'erro': 'Campos "nome" e "filmeId" são obrigatórios'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final filme = await filmeDb.getById(data['filmeId'] as int);
      if (filme == null) {
        return Response(404,
          body: jsonEncode({'erro': 'Filme com ID ${data['filmeId']} não encontrado.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final novoAtor = Ator(
        id: 0,
        nome: data['nome'] as String,
        personagem: data['personagem'] as String,
        idade: data['idade'] as int,
        filmeId: data['filmeId'] as int,
      );

      final criado = await atorDb.insert(novoAtor);

      return Response(201,
        body: jsonEncode(criado.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'erro': 'Erro ao processar requisição: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // PUT /atores/<id> — Atualizar ator
  router.put('/atores/<id>', (Request request, String id) async {
    final atorId = int.tryParse(id);
    if (atorId == null) {
      return Response(400,
        body: jsonEncode({'erro': 'ID inválido'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final filme = await filmeDb.getById(data['filmeId'] as int);
      if (filme == null) {
        return Response(404,
          body: jsonEncode({'erro': 'Filme com ID ${data['filmeId']} não encontrado.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final atorEditado = Ator(
        id: atorId,
        nome: data['nome'] as String,
        personagem: data['personagem'] as String,
        idade: data['idade'] as int,
        filmeId: data['filmeId'] as int,
      );

      final resultado = await atorDb.update(atorId, atorEditado);
      if (resultado == null) {
        return Response(404,
          body: jsonEncode({'erro': 'Ator não encontrado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(resultado.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'erro': 'Erro: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // DELETE /atores/<id>
  router.delete('/atores/<id>', (Request request, String id) async {
    final atorId = int.tryParse(id);
    if (atorId == null) {
      return Response(400,
        body: jsonEncode({'erro': 'ID inválido'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final deletou = await atorDb.delete(atorId);
    if (!deletou) {
      return Response(404,
        body: jsonEncode({'erro': 'Ator não encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response(204);
  });

  return router;
}
