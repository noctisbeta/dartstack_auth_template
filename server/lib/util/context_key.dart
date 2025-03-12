enum ContextKey {
  userId('userId'),
  healthService('healthService'),
  postgresService('postgresService'),
  migrationService('migrationService'),
  agendaRepository('agendaRepository'),
  agendaHandler('agendaHandler'),
  agendaDataSource('agendaDataSource'),
  authRepository('authRepository'),
  authHandler('authHandler'),
  authDataSource('authDataSource'),
  projectsDataSource('projectsDataSource'),
  projectsRepository('projectsRepository'),
  projectsHandler('projectsHandler'),
  diagramsDataSource('diagramsDataSource'),
  diagramsRepository('diagramsRepository'),
  diagramsHandler('diagramsHandler');

  const ContextKey(this.keyString);

  final String keyString;
}
