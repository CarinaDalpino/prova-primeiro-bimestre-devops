Relatório do Processo - Prova do Primeiro Bimestre (DevOps)

Aluno: Carina Gonçalves dos Santos Dalpino
RA: 6325109
Data: 27/09/2026
Ferramenta de IA utilizada: Kiro (Spec-Driven / assistente de código)

Questão 1 - A Jornada Completa (Aulas 01 a 07)

Durante a prova, procurei seguir uma sequência que fizesse sentido com o que aprendemos durante o bimestre. Primeiro trabalhei com o Git e GitHub, criando o repositório do projeto e utilizando branches para organizar as etapas do desenvolvimento. Também procurei manter os commits organizados para conseguir acompanhar melhor o que estava sendo alterado em cada etapa.

Depois passei para a construção da API de Reservas utilizando Node.js e Express. Desenvolvi as funcionalidades de cadastro, consulta, alteração e exclusão das reservas, utilizando o PostgreSQL para armazenar os dados. Essa parte foi importante porque foi a base para depois conseguir colocar a aplicação em um ambiente com Docker.

Na sequência, utilizei o Docker, criando o Dockerfile para colocar a aplicação dentro de um container. Depois utilizei o Docker Compose, que facilitou bastante a execução da API junto com o banco PostgreSQL no ambiente local. Com o Compose, consegui subir os serviços juntos e testar a aplicação antes de levar para a AWS.

Depois que a aplicação estava funcionando localmente, comecei a parte de infraestrutura utilizando Terraform. Criei a estrutura da AWS utilizando VPC, subnets, Security Groups, EC2 e RDS. Também trabalhei com os módulos aprendidos na Aula 06, separando partes da infraestrutura para facilitar a organização e o reaproveitamento.

Na parte de Remote State, utilizei o S3 para armazenar o state e o DynamoDB para fazer o controle de locking. No Learner Lab precisei fazer alguns ajustes porque existem algumas limitações no ambiente, então o bucket do state precisou ser criado utilizando a AWS CLI.

A Aula 07, sobre o uso da IA como copiloto, esteve presente durante praticamente todo o desenvolvimento. Utilizei o Kiro para me ajudar a entender, criar e revisar partes do projeto, mas procurei sempre testar o que ele gerava antes de considerar a tarefa concluída.

Para mim, a sequência Git → Docker → Compose → Terraform → Modules → Remote State ajudou a entender como cada conhecimento do bimestre foi sendo utilizado na construção do projeto completo.

Questão 2 - O Processo com IA como Copiloto

Durante a prova utilizei o Kiro como ferramenta de IA e copiloto de desenvolvimento. Eu não queria simplesmente pedir para a ferramenta fazer todo o projeto de uma vez. Procurei dividir o trabalho em partes menores e explicar o que precisava ser feito em cada etapa.

Um dos principais tipos de pedido que fiz foi explicar o que eu precisava implementar e quais eram as limitações do ambiente. Por exemplo, informei que estava trabalhando no AWS Academy Learner Lab e que não poderia criar recursos próprios de IAM. Isso foi importante porque o ambiente possui algumas restrições diferentes de uma conta AWS normal.

O Kiro me ajudou principalmente na criação da estrutura dos módulos Terraform, nas rotas da API, no Dockerfile, no Docker Compose e na organização da infraestrutura. Ele também ajudou bastante quando eu precisava entender um erro ou pensar em uma forma de organizar determinada parte do projeto.

Mas também percebi que não poderia simplesmente aceitar tudo que a IA apresentava. Durante os testes apareceram situações que só consegui identificar porque executei o código de verdade. Um exemplo foi o problema de conexão entre a aplicação no EC2 e o RDS, relacionado ao SSL do PostgreSQL. Foi necessário ajustar a configuração do pg para permitir a conexão corretamente.

Outro problema aconteceu com o Remote State. O Learner Lab possui restrições que impediram que o bucket do S3 fosse criado da maneira inicialmente planejada pelo Terraform. Nesse caso, precisei adaptar a solução e criar o bucket utilizando a AWS CLI.

Comparando com fazer tudo manualmente, percebi que a IA economizou bastante tempo principalmente na parte de escrever códigos repetitivos e montar estruturas iniciais. Por outro lado, também percebi que ela pode gerar uma solução que parece correta, mas que precisa ser testada no ambiente real.

O uso do Kiro me mostrou que a IA funciona melhor para mim quando eu utilizo como copiloto, e não como alguém que simplesmente faz o projeto inteiro sozinho. Eu continuo precisando entender o que está sendo feito, testar e decidir se a solução realmente atende ao problema.

Questão 3 - Infraestrutura, Segurança e o Learner Lab

A infraestrutura que montei na AWS foi organizada dentro de uma VPC 10.0.0.0/16, utilizando duas Availability Zones. Dentro dela, configurei quatro subnets, sendo duas públicas e duas privadas.

A aplicação ficou em uma EC2 dentro de uma subnet pública, porque precisava receber acesso externo para que a API pudesse ser acessada. A EC2 possui IP público e acesso ao Internet Gateway. O RDS, por outro lado, ficou em uma subnet privada, porque o banco de dados não precisa ficar diretamente exposto à internet.

A comunicação com o banco foi controlada por Security Groups. O RDS utiliza a porta 5432 para o PostgreSQL e o acesso foi restringido para permitir a comunicação necessária com a aplicação. Também configurei o RDS com publicly_accessible = false, evitando que ele fique acessível diretamente pela internet, e utilizei criptografia no armazenamento.

No Learner Lab precisei prestar atenção principalmente nas limitações de IAM. Como o ambiente não permite que eu crie livremente usuários, grupos e roles, utilizei o LabInstanceProfile já disponibilizado pelo próprio ambiente para a EC2.

Também precisei trabalhar com as credenciais temporárias do AWS Academy, que possuem tempo de validade. Em alguns momentos, quando a sessão expirou, foi necessário atualizar as credenciais para conseguir continuar utilizando a AWS.

Outra configuração importante foi manter a região utilizada no projeto como us-east-1, de acordo com o ambiente do Learner Lab.

O Learner Lab também trouxe algumas diferenças em relação ao que foi apresentado nas aulas. Algumas ações que poderiam funcionar normalmente em uma conta AWS comum são bloqueadas pelas políticas do laboratório. Por isso precisei adaptar a criação do Remote State e utilizar a AWS CLI para criar o bucket do S3.

Essa parte foi importante para eu perceber que não basta conhecer o Terraform apenas na teoria. Também precisamos entender o ambiente onde estamos trabalhando e suas limitações.

Questão 4 - Validação e Responsabilidade

Antes de executar um terraform apply, procurei não confiar diretamente no código que havia sido gerado pela IA. Primeiro fiz algumas verificações para entender o que realmente seria criado na AWS.

Um dos primeiros passos foi executar o terraform validate, para verificar se a configuração estava correta. Depois utilizei o terraform plan, que foi muito importante porque permitiu visualizar os recursos que seriam criados ou alterados antes de executar o apply.

Também conferi se não havia recursos de IAM sendo criados, porque isso não seria permitido no Learner Lab. Verifiquei a configuração do RDS para confirmar que ele estava com publicly_accessible = false e com a criptografia habilitada.

Outro cuidado foi verificar o .gitignore, principalmente para evitar que arquivos como terraform.tfstate, arquivos .tfvars e chaves fossem enviados para o GitHub.

Depois de provisionar a infraestrutura, também fiz testes para verificar se tudo estava funcionando. A aplicação foi executada na EC2, consegui verificar a conexão com o banco e o health check retornou db: connected. Também testei as operações do CRUD para confirmar que a aplicação conseguia gravar e consultar informações no RDS.

Durante o desenvolvimento tive uma situação que mostrou ainda mais a importância de revisar o que estamos fazendo. Em determinado momento, um terraform destroy executado sobre um state que estava contaminado acabou removendo recursos de outro projeto meu. Foi uma situação que me fez perceber na prática como é importante separar corretamente o state de cada projeto e conferir o que será destruído antes de confirmar uma operação.

Se eu simplesmente aceitasse tudo que a IA gerasse sem revisar, poderia ter problemas como a aplicação não conseguir se conectar ao RDS, recursos não permitidos pelo Learner Lab serem criados ou até recursos importantes serem destruídos.

A evolução que tivemos durante o bimestre, passando por Git, Docker, Terraform e Modules, me ajudou justamente nessa parte. Como fui entendendo cada tecnologia aos poucos, consegui acompanhar melhor o que a IA estava criando e identificar quando alguma coisa não fazia sentido.

No final, meu principal aprendizado foi que a IA pode acelerar bastante o desenvolvimento, mas a responsabilidade continua sendo minha. Eu preciso entender o código, revisar, testar e validar antes de executar qualquer alteração na infraestrutura.