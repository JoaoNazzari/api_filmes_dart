import 'package:apidart/database.dart';
import 'package:apidart/middleware.dart';
import 'package:apidart/filmes_router.dart';
import 'package:apidart/atores_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main() async {
  // Inicializa o banco de dados PostgreSQL (Neon)
  final db = DatabaseHelper();
  await db.initialize();
  print('✅ Banco de dados PostgreSQL (Neon) inicializado');

  // Combina os dois routers com Cascade
  final cascade = Cascade()
      .add(atorRouter(db).call)
      .add(filmeRouter(db).call);

  // Cria o pipeline: Middleware → Router
  final handler = Pipeline()
      .addMiddleware(logMiddleware())
      .addMiddleware(corsMiddleware())
      .addMiddleware(authMiddleware())
      .addHandler(cascade.handler);

  // Inicia o servidor
  final server = await io.serve(handler, 'localhost', 8080);
  print('🚀 Servidor rodando em http://${server.address.host}:${server.port}');
  print('📋 Endpoints disponíveis:');
  print('   --- Filmes (pai) ---');
  print('   GET    /filmes                          → Listar todos');
  print('   GET    /filmes/<id>                     → Buscar por Id');
  print('   GET    /filmes?idade=14                 → Filtro por idade');
  print('   GET    /filmes?genero=Acao              → Filtro por gênero');
  print('   GET    /filmes?idade=14&genero=Acao     → Filtro por idade e gênero');
  print('   POST   /filmes                          → Criar novo');
  print('   PUT    /filmes/<id>                     → Atualizar');
  print('   DELETE /filmes/<id>                     → Deletar');
  print('   --- Atores (filho) ---');
  print('   GET    /atores                          → Listar todos');
  print('   GET    /atores/<id>                     → Buscar por Id');
  print('   GET    /filmes/<id>/atores              → Listar atores de um filme');
  print('   POST   /atores                          → Criar novo');
  print('   PUT    /atores/<id>                     → Atualizar');
  print('   DELETE /atores/<id>                     → Deletar');
}
