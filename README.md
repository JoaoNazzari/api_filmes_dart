# API REST com Dart + PostgreSQL (Neon) — Guia Passo a Passo

## Sobre este projeto

Neste guia você vai construir do zero uma **API REST completa** usando Dart puro com persistência em PostgreSQL via [Neon](https://neon.tech). A API gerencia **Filmes** e **Atores** (CRUD completo) com relacionamento pai-filho, além de middlewares de logging, CORS e autenticação por token.

**Stack utilizada:**

- **Dart SDK** — linguagem de programação
- **shelf** — servidor HTTP leve (similar ao Express.js do Node)
- **shelf_router** — sistema de rotas
- **postgres** — driver PostgreSQL para Dart (conexão com Neon)

---

## Pré-requisitos

1. **Dart SDK** instalado (versão 3.0+)
   - Verifique com: `dart --version`
   - Download: [https://dart.dev/get-dart](https://dart.dev/get-dart)

2. **Conta no Neon** para o banco de dados PostgreSQL
   - Cadastre-se em: [https://neon.tech](https://neon.tech)
   - Crie um projeto e copie a connection string (formato: `postgresql://user:password@host/dbname?sslmode=require`)

3. **Postman** ou **Insomnia** para testar a API
   - Postman: [https://www.postman.com/downloads](https://www.postman.com/downloads)
   - Insomnia: [https://insomnia.rest/download](https://insomnia.rest/download)
   - Ou use a extensão **Thunder Client** no VS Code

---

## 1. Criando o projeto

```bash
dart create -t console apidart
cd apidart
```

Edite o `pubspec.yaml`:

```yaml
name: apidart
description: API REST CRUD de Filmes e Atores com Dart + PostgreSQL
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.0
  postgres: ^3.0.0
```

Instale as dependências:

```bash
dart pub get
```

---

## 2. Estrutura de pastas

```
apidart/
├── bin/
│   └── server.dart              ← Ponto de entrada
├── lib/
│   ├── database.dart            ← Conexão e CRUD de Filmes (PostgreSQL)
│   ├── ator_database.dart       ← Conexão e CRUD de Atores (PostgreSQL)
│   ├── middleware.dart           ← Logger, CORS e Auth
│   ├── filmes_router.dart        ← Rotas CRUD de Filmes
│   ├── atores_router.dart        ← Rotas CRUD de Atores
│   └── models/
│       ├── filme.dart            ← Modelo Filme
│       └── atores.dart           ← Modelo Ator
├── .env                          ← Connection string do Neon (não versionar)
└── pubspec.yaml
```

---

## 3. Variável de ambiente

Crie um arquivo `.env` na raiz do projeto (e adicione ao `.gitignore`):

```
postgresql://usuario:senha@host/dbname?sslmode=require
```

O `DatabaseHelper` e o `AtorDatabaseHelper` leem essa string para se conectar ao Neon.

> ⚠️ **Nunca comite o arquivo `.env` com credenciais reais.**

---

## 4. Criando os Modelos

### `lib/models/filme.dart`

```dart
class Filme {
  final int id;
  final String titulo;
  final String genero;
  final String duracao;
  final int faixaEtaria;

  Filme({
    required this.id,
    required this.titulo,
    required this.genero,
    required this.duracao,
    required this.faixaEtaria,
  });

  factory Filme.fromMap(Map<String, dynamic> map) {
    return Filme(
      id: map['id'] as int,
      titulo: map['titulo'] as String,
      genero: map['genero'] as String,
      duracao: map['duracao'] as String,
      faixaEtaria: map['faixaEtaria'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'genero': genero,
    'duracao': duracao,
    'faixaEtaria': faixaEtaria,
  };
}
```

### `lib/models/atores.dart`

```dart
class Ator {
  final int id;
  String nome;
  String personagem;
  int idade;
  int filmeId;

  Ator({
    required this.id,
    required this.nome,
    required this.personagem,
    required this.idade,
    required this.filmeId,
  });

  factory Ator.fromMap(Map<String, dynamic> map) {
    return Ator(
      id: map['id'] as int,
      nome: map['nome'] as String,
      personagem: map['personagem'] as String,
      idade: map['idade'] as int,
      filmeId: map['filmeId'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'personagem': personagem,
    'idade': idade,
    'filmeId': filmeId,
  };
}
```

---

## 5. Configurando os Bancos de Dados

### `lib/database.dart` — Filmes

Gerencia a tabela `filmes` no PostgreSQL/Neon. Métodos disponíveis:

| Método | Descrição |
|--------|-----------|
| `initialize()` | Cria a tabela se não existir |
| `getAll()` | Retorna todos os filmes |
| `getAllowedByAge(int idade)` | Retorna filmes com `faixaEtaria <= idade` |
| `getByGenre(String genero)` | Retorna filmes pelo gênero |
| `getByAgeAndGenre(int idade, String genero)` | Filtro duplo |
| `getById(int id)` | Busca por ID |
| `insert(Filme filme)` | Insere e retorna com ID gerado |
| `update(int id, Filme filme)` | Atualiza e retorna o registro |
| `delete(int id)` | Deleta; retorna `true` se removeu |

### `lib/ator_database.dart` — Atores

Gerencia a tabela `atores` no PostgreSQL/Neon. Métodos disponíveis:

| Método | Descrição |
|--------|-----------|
| `initialize()` | Cria a tabela se não existir |
| `getAll()` | Retorna todos os atores |
| `getById(int id)` | Busca por ID |
| `getByFilmeId(int filmeId)` | Retorna os atores de um filme |
| `insert(Ator ator)` | Insere e retorna com ID gerado |
| `update(int id, Ator ator)` | Atualiza e retorna o registro |
| `delete(int id)` | Deleta; retorna `true` se removeu |

---

## 6. Criando os Middlewares

Arquivo `lib/middleware.dart` com três middlewares encadeados:

```dart
import 'package:shelf/shelf.dart';

Middleware logMiddleware() { ... }   // Loga método, URL, status e tempo
Middleware corsMiddleware() { ... }  // Adiciona headers CORS em toda resposta
Middleware authMiddleware() { ... }  // Exige header Authorization: 123
```

**O que cada um faz:**

- **logMiddleware** — exibe no console cada request com método, caminho, status e tempo de resposta em ms
- **corsMiddleware** — adiciona os headers `Access-Control-Allow-*` e responde requisições `OPTIONS` (preflight) com `200` imediatamente
- **authMiddleware** — bloqueia qualquer requisição sem o header `Authorization: 123`, retornando `401`

---

## 7. Definindo as Rotas

### `lib/filmes_router.dart`

```dart
Router filmeRouter(DatabaseHelper db) { ... }
```

### `lib/atores_router.dart`

```dart
Router atorRouter(AtorDatabaseHelper atorDb, DatabaseHelper filmeDb) { ... }
```

> O router de atores recebe **dois** helpers: o próprio `AtorDatabaseHelper` e o `DatabaseHelper` de filmes — necessário para validar se o `filmeId` informado existe antes de criar/editar um ator.

---

## 8. Ponto de Entrada

Arquivo `bin/server.dart`:

```dart
import 'package:apidart/database.dart';
import 'package:apidart/ator_database.dart';
import 'package:apidart/middleware.dart';
import 'package:apidart/filmes_router.dart';
import 'package:apidart/atores_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main() async {
  final db = DatabaseHelper();
  await db.initialize();

  final atorDb = AtorDatabaseHelper();
  await atorDb.initialize();

  final cascade = Cascade()
      .add(atorRouter(atorDb, db).call)
      .add(filmeRouter(db).call);

  final handler = Pipeline()
      .addMiddleware(logMiddleware())
      .addMiddleware(corsMiddleware())
      .addMiddleware(authMiddleware())
      .addHandler(cascade.handler);

  final server = await io.serve(handler, 'localhost', 8080);
  print('🚀 Servidor rodando em http://${server.address.host}:${server.port}');
}
```

**Por que `Cascade`?** Os dois routers são independentes. O `Cascade` tenta o primeiro router (`atorRouter`) e, se ele não reconhecer a rota (retornar 404), passa para o segundo (`filmeRouter`).

---

## 9. Rodando o projeto

```bash
dart run bin/server.dart
```

Saída esperada:

```
✅ Banco de dados PostgreSQL (Neon) inicializado
🚀 Servidor rodando em http://localhost:8080
```

---

## 10. Autenticação

Todas as rotas exigem o header `Authorization` com o valor exato `123`.

Sem ele (ou com valor errado), a API retorna:

```
HTTP 401 — Acesso negado: Token de autenticação inválido ou ausente.
```

No Postman, adicione em **Headers**:

| Key | Value |
|-----|-------|
| `Authorization` | `123` |

---

## 11. Endpoints disponíveis

### Filmes (pai)

| Método | Rota | Descrição | Status |
|--------|------|-----------|--------|
| GET | `/filmes` | Listar todos | 200 |
| GET | `/filmes/<id>` | Buscar por ID | 200 / 404 |
| GET | `/filmes?idade=14` | Filtrar por faixa etária | 200 |
| GET | `/filmes?genero=Acao` | Filtrar por gênero | 200 |
| GET | `/filmes?idade=14&genero=Acao` | Filtrar por idade e gênero | 200 |
| POST | `/filmes` | Criar novo filme | 201 / 400 |
| PUT | `/filmes/<id>` | Atualizar filme | 200 / 404 |
| DELETE | `/filmes/<id>` | Deletar filme | 200 / 404 |

### Atores (filho)

| Método | Rota | Descrição | Status |
|--------|------|-----------|--------|
| GET | `/atores` | Listar todos | 200 |
| GET | `/atores/<id>` | Buscar por ID | 200 / 404 |
| GET | `/filmes/<id>/atores` | Listar atores de um filme | 200 / 404 |
| POST | `/atores` | Criar novo ator | 201 / 400 / 404 |
| PUT | `/atores/<id>` | Atualizar ator | 200 / 404 |
| DELETE | `/atores/<id>` | Deletar ator | 204 / 404 |

> Todos os endpoints exigem o header `Authorization: 123`.

---

## 12. Testando com Postman / Insomnia

### Criar um filme (POST)

- **URL:** `POST http://localhost:8080/filmes`
- **Headers:** `Content-Type: application/json`, `Authorization: 123`
- **Body:**

```json
{
  "titulo": "Interestelar",
  "genero": "Ficcao",
  "duracao": "2h49min",
  "faixaEtaria": 12
}
```

**Resposta (201):**

```json
{
  "id": 1,
  "titulo": "Interestelar",
  "genero": "Ficcao",
  "duracao": "2h49min",
  "faixaEtaria": 12
}
```

### Criar um ator (POST)

- **URL:** `POST http://localhost:8080/atores`
- **Body:**

```json
{
  "nome": "Matthew McConaughey",
  "personagem": "Cooper",
  "idade": 54,
  "filmeId": 1
}
```

> O campo `filmeId` deve referenciar um filme existente. Caso contrário, a API retorna `404`.

### Listar atores de um filme (GET)

- **URL:** `GET http://localhost:8080/filmes/1/atores`

### Filtrar filmes por idade e gênero (GET)

- **URL:** `GET http://localhost:8080/filmes?idade=14&genero=Acao`

### Atualizar filme (PUT)

- **URL:** `PUT http://localhost:8080/filmes/1`
- **Body:**

```json
{
  "titulo": "Interestelar",
  "genero": "Ficcao Cientifica",
  "duracao": "2h49min",
  "faixaEtaria": 12
}
```

### Deletar ator (DELETE)

- **URL:** `DELETE http://localhost:8080/atores/1`
- **Resposta:** `204 No Content`

---

## 13. Testando com curl (Terminal)

```bash
# Criar filme
curl -X POST http://localhost:8080/filmes \
  -H "Content-Type: application/json" \
  -H "Authorization: 123" \
  -d '{"titulo":"Interestelar","genero":"Ficcao","duracao":"2h49min","faixaEtaria":12}'

# Listar todos os filmes
curl http://localhost:8080/filmes -H "Authorization: 123"

# Filtrar por idade
curl "http://localhost:8080/filmes?idade=14" -H "Authorization: 123"

# Filtrar por gênero
curl "http://localhost:8080/filmes?genero=Acao" -H "Authorization: 123"

# Filtrar por idade e gênero
curl "http://localhost:8080/filmes?idade=14&genero=Acao" -H "Authorization: 123"

# Criar ator
curl -X POST http://localhost:8080/atores \
  -H "Content-Type: application/json" \
  -H "Authorization: 123" \
  -d '{"nome":"Matthew McConaughey","personagem":"Cooper","idade":54,"filmeId":1}'

# Listar atores de um filme
curl http://localhost:8080/filmes/1/atores -H "Authorization: 123"

# Atualizar ator
curl -X PUT http://localhost:8080/atores/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: 123" \
  -d '{"nome":"Matthew McConaughey","personagem":"Cooper","idade":55,"filmeId":1}'

# Deletar ator
curl -X DELETE http://localhost:8080/atores/1 -H "Authorization: 123"

# Deletar filme
curl -X DELETE http://localhost:8080/filmes/1 -H "Authorization: 123"
```

---

## Referências

- [Documentação do Shelf](https://pub.dev/packages/shelf)
- [Shelf Router](https://pub.dev/packages/shelf_router)
- [postgres para Dart](https://pub.dev/packages/postgres)
- [Neon — PostgreSQL Serverless](https://neon.tech/docs)
- [Postman Learning Center](https://learning.postman.com)
- [OpenAPI / Swagger](https://swagger.io/specification/)
