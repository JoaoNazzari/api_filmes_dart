# API REST com Dart + SQLite — Guia Passo a Passo

## Sobre este projeto

Neste guia você vai construir do zero uma **API REST completa** usando Dart puro com persistência em SQLite. A API gerencia **Filmes** (CRUD) e inclui middlewares de logging, CORS e autenticação por token.

**Stack utilizada:**

- **Dart SDK** — linguagem de programação
- **shelf** — servidor HTTP leve (similar ao Express.js do Node)
- **shelf_router** — sistema de rotas
- **sqlite3** — banco de dados SQLite nativo

---

## Pré-requisitos

1. **Dart SDK** instalado (versão 3.0+)  
   - Verifique com: `dart --version`
   - Download: [https://dart.dev/get-dart](https://dart.dev/get-dart)

2. **Postman** ou **Insomnia** instalado para testar a API  
   - Postman: [https://www.postman.com/downloads](https://www.postman.com/downloads)
   - Insomnia: [https://insomnia.rest/download](https://insomnia.rest/download)
   - Ou use a extensão **Thunder Client** no VS Code

---

## 1. Criando o projeto

Abra o terminal e execute:

```bash
dart create -t console api_filmes
cd api_filmes
```

Agora edite o `pubspec.yaml` para adicionar as dependências:

```yaml
name: api_filmes
description: API REST CRUD de Filmes com Dart + SQLite
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.0
  sqlite3: ^2.1.0
```

Instale as dependências:

```bash
dart pub get
```

---

## 2. Estrutura de pastas

Organize o projeto assim:

```
api_filmes/
├── bin/
│   └── server.dart          ← Ponto de entrada
├── lib/
│   ├── database.dart        ← Conexão SQLite
│   ├── middleware.dart       ← Logger, CORS e Auth
│   ├── router.dart           ← Rotas CRUD
│   └── models/
│       └── filme.dart        ← Modelo de dados
├── pubspec.yaml
└── filmes.db                 ← Banco (criado automaticamente)
```

---

## 3. Criando o Modelo (Filme)

Crie o arquivo `lib/models/filme.dart`:

```dart
class Filme {
  final int? id;
  final String titulo;
  final String genero;
  final String duracao;
  final int faixa_etaria;

  Filme({
    this.id,
    required this.titulo,
    required this.genero,
    required this.duracao,
    required this.faixa_etaria,
  });

  /// Cria um Filme a partir de um Map (banco de dados)
  factory Filme.fromMap(Map<String, dynamic> map) {
    return Filme(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      genero: map['genero'] as String,
      duracao: map['duracao'] as String,
      faixa_etaria: map['faixa_etaria'] as int,
    );
  }

  /// Converte para JSON (resposta da API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'genero': genero,
      'duracao': duracao,
      'faixa_etaria': faixa_etaria,
    };
  }
}
```

**O que está acontecendo aqui?**

- `fromMap` — converte um registro do banco para um objeto Dart
- `toJson` — converte para devolver na resposta da API

---

## 4. Configurando o Banco de Dados (SQLite)

Crie o arquivo `lib/database.dart`:

```dart
import 'package:sqlite3/sqlite3.dart';
import 'models/filme.dart';

class DatabaseHelper {
  late Database _db;

  void initialize() {
    _db = sqlite3.open('filmes.db');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS filmes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        genero TEXT NOT NULL,
        duracao TEXT NOT NULL,
        faixa_etaria INTEGER NOT NULL DEFAULT 0
      );
    ''');
  }

  /// Retorna todos os filmes
  List<Filme> getAll() {
    final result = _db.select('SELECT * FROM filmes ORDER BY id DESC');
    return result.map((row) => Filme.fromMap(row)).toList();
  }

  /// Filtra por idade permitida E gênero ao mesmo tempo
  List<Filme> getByAgeAndGenre(int idade, String genero) {
    final result = _db.select(
      'SELECT * FROM filmes WHERE faixa_etaria <= ? AND genero = ? ORDER BY id DESC',
      [idade, genero],
    );
    return result.map((row) => Filme.fromMap(row)).toList();
  }

  /// Retorna filmes permitidos para uma determinada idade
  List<Filme> getAllowedByAge(int idadeUsuario) {
    final result = _db.select(
      'SELECT * FROM filmes WHERE faixa_etaria <= ? ORDER BY faixa_etaria DESC',
      [idadeUsuario],
    );
    return result.map((row) => Filme.fromMap(row)).toList();
  }

  /// Retorna filmes filtrados pelo gênero
  List<Filme> getByGenre(String genero) {
    final result = _db.select(
      'SELECT * FROM filmes WHERE genero = ? ORDER BY id DESC',
      [genero],
    );
    return result.map((row) => Filme.fromMap(row)).toList();
  }

  /// Busca um Filme pelo ID
  Filme? getById(int id) { ... }

  /// Insere um novo Filme
  Filme insert(Filme filme) { ... }

  /// Atualiza um Filme existente
  Filme? update(int id, Filme filme) { ... }

  /// Deleta um Filme pelo ID
  bool delete(int id) { ... }
}
```

**Pontos importantes:**

- `faixa_etaria` é armazenado como inteiro — a query usa `<=` para retornar filmes permitidos para a idade informada
- Usamos `?` nas queries para evitar SQL Injection
- `lastInsertRowId` retorna o ID auto-gerado após um INSERT

---

## 5. Criando os Middlewares

Crie o arquivo `lib/middleware.dart`. Este projeto possui três middlewares encadeados:

```dart
import 'package:shelf/shelf.dart';

/// Middleware de logging — registra método, URL e tempo de resposta
Middleware logMiddleware() { ... }

/// Middleware de CORS — permite que frontends em outros domínios consumam a API
Middleware corsMiddleware() { ... }

/// Middleware de Autenticação — protege todas as rotas com token fixo
Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      if (authHeader == '123') {
        return await innerHandler(request);
      } else {
        return Response(
          401,
          body: 'Acesso negado: Token de autenticação inválido ou ausente.',
          headers: {'Content-Type': 'text/plain'},
        );
      }
    };
  };
}
```

**O que cada middleware faz:**

- **logMiddleware** — registra no console cada request com método, URL, status code e tempo de resposta
- **corsMiddleware** — adiciona headers CORS em toda resposta e responde requisições `OPTIONS` (preflight) automaticamente
- **authMiddleware** — exige o header `Authorization: 123` em toda requisição; retorna `401` caso contrário

---

## 6. Definindo as Rotas (Router)

Crie o arquivo `lib/router.dart`:

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'database.dart';
import 'models/filme.dart';

Router filmeRouter(DatabaseHelper db) {
  final router = Router();

  // GET /filmes — Listar todos, com filtros opcionais por idade e/ou gênero
  router.get('/filmes', (Request request) {
    final params = request.requestedUri.queryParameters;
    final idadeStr = params['idade'];
    final genero = params['genero'];

    List<Filme> filmes;

    if (idadeStr != null && genero != null) {
      filmes = db.getByAgeAndGenre(int.parse(idadeStr), genero);
    } else if (idadeStr != null) {
      filmes = db.getAllowedByAge(int.parse(idadeStr));
    } else if (genero != null) {
      filmes = db.getByGenre(genero);
    } else {
      filmes = db.getAll();
    }

    return Response.ok(
      jsonEncode(filmes.map((f) => f.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // POST /filmes — Criar novo filme
  router.post('/filmes', (Request request) async { ... });

  // PUT /filmes/<id> — Atualizar filme
  router.put('/filmes/<id>', (Request request, String id) async { ... });

  // DELETE /filmes/<id> — Deletar filme
  router.delete('/filmes/<id>', (Request request, String id) { ... });

  return router;
}
```

---

## 7. Ponto de Entrada (Server)

Crie o arquivo `bin/server.dart`:

```dart
import 'package:apidart/database.dart';
import 'package:apidart/middleware.dart';
import 'package:apidart/router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main() async {
  final db = DatabaseHelper();
  db.initialize();
  print('✅ Banco de dados SQLite inicializado');

  final handler = Pipeline()
      .addMiddleware(logMiddleware())
      .addMiddleware(corsMiddleware())
      .addMiddleware(authMiddleware())
      .addHandler(filmeRouter(db));

  final server = await io.serve(handler, 'localhost', 8080);
  print('🚀 Servidor rodando em http://${server.address.host}:${server.port}');
}
```

---

## 8. Rodando o projeto

```bash
dart run bin/server.dart
```

Saída esperada:

```
✅ Banco de dados SQLite inicializado
🚀 Servidor rodando em http://localhost:8080
```

---

## 9. Autenticação

Todas as rotas exigem o header `Authorization` com o valor `123`.

Sem o header correto, a API retorna:

```
HTTP 401 — Acesso negado: Token de autenticação inválido ou ausente.
```

No Postman, adicione em **Headers**:

| Key | Value |
|-----|-------|
| `Authorization` | `123` |

---

## 10. Testando com Postman / Insomnia

> ⚠️ Lembre-se de incluir o header `Authorization: 123` em todas as requisições.

### Criar um filme (POST)

- **Método:** POST  
- **URL:** `http://localhost:8080/filmes`  
- **Headers:** `Content-Type: application/json`, `Authorization: 123`  
- **Body (JSON):**

```json
{
  "titulo": "Interestelar",
  "genero": "Ficcao",
  "duracao": "2h49min",
  "faixa_etaria": 12
}
```

**Resposta esperada (201 Created):**

```json
{
  "id": 1,
  "titulo": "Interestelar",
  "genero": "Ficcao",
  "duracao": "2h49min",
  "faixa_etaria": 12
}
```

### Listar todos os filmes (GET)

- **URL:** `http://localhost:8080/filmes`

### Filtrar por idade (GET)

Retorna filmes com `faixa_etaria` menor ou igual à idade informada:

- **URL:** `http://localhost:8080/filmes?idade=14`

### Filtrar por gênero (GET)

- **URL:** `http://localhost:8080/filmes?genero=Acao`

### Filtrar por idade e gênero (GET)

- **URL:** `http://localhost:8080/filmes?idade=14&genero=Acao`

### Atualizar (PUT)

- **Método:** PUT  
- **URL:** `http://localhost:8080/filmes/1`  
- **Body:**

```json
{
  "titulo": "Interestelar",
  "genero": "Ficcao Cientifica",
  "duracao": "2h49min",
  "faixa_etaria": 12
}
```

### Deletar (DELETE)

- **Método:** DELETE  
- **URL:** `http://localhost:8080/filmes/1`

**Resposta:**

```json
{
  "mensagem": "Filme deletado com sucesso"
}
```

---

## 11. Testando com curl (Terminal)

```bash
# Criar filme
curl -X POST http://localhost:8080/filmes \
  -H "Content-Type: application/json" \
  -H "Authorization: 123" \
  -d '{"titulo": "Interestelar", "genero": "Ficcao", "duracao": "2h49min", "faixa_etaria": 12}'

# Listar todos
curl http://localhost:8080/filmes -H "Authorization: 123"

# Filtrar por idade
curl "http://localhost:8080/filmes?idade=14" -H "Authorization: 123"

# Filtrar por gênero
curl "http://localhost:8080/filmes?genero=Acao" -H "Authorization: 123"

# Filtrar por idade e gênero
curl "http://localhost:8080/filmes?idade=14&genero=Acao" -H "Authorization: 123"

# Atualizar
curl -X PUT http://localhost:8080/filmes/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: 123" \
  -d '{"titulo": "Interestelar", "genero": "Ficcao Cientifica", "duracao": "2h49min", "faixa_etaria": 12}'

# Deletar
curl -X DELETE http://localhost:8080/filmes/1 -H "Authorization: 123"
```

---

## Resumo dos Endpoints

| Método | Rota | Descrição | Status |
|--------|------|-----------|--------|
| GET | `/filmes` | Listar todos os filmes | 200 |
| GET | `/filmes?idade=14` | Filtrar por faixa etária | 200 |
| GET | `/filmes?genero=Acao` | Filtrar por gênero | 200 |
| GET | `/filmes?idade=14&genero=Acao` | Filtrar por idade e gênero | 200 |
| POST | `/filmes` | Criar novo filme | 201 / 400 |
| PUT | `/filmes/<id>` | Atualizar filme | 200 / 404 |
| DELETE | `/filmes/<id>` | Deletar filme | 200 / 404 |

> Todos os endpoints exigem o header `Authorization: 123`.

---

## Referências

- [Documentação do Shelf](https://pub.dev/packages/shelf)
- [Shelf Router](https://pub.dev/packages/shelf_router)
- [SQLite3 para Dart](https://pub.dev/packages/sqlite3)
- [Postman Learning Center](https://learning.postman.com)
- [OpenAPI / Swagger](https://swagger.io/specification/)
