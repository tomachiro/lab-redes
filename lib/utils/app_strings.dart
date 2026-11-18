class AppStrings {
  static const String appName = 'FitBook';

  static const String themeTitle = 'Apariencia';
  static const String themeLight = 'Claro';
  static const String themeDark = 'Oscuro';
  static const String themeWarm = 'Descanso Visual (Cálido)';

  static const String usernameLabel = 'Usuario o Correo electrónico';
  static const String passwordLabel = 'Contraseña';
  static const String loginButton = 'Iniciar Sesión';
  static const String createAccountButton = 'Crear Cuenta';
  static const String hasAccountQuestion =
      '¿Ya tienes una cuenta? Inicia sesión';
  static const String noAccountQuestion = '¿No tienes cuenta? Regístrate';
  static const String anonymousGuestButton = 'Entrar como Invitado Anónimo';
  static const String emptyCredentialsError =
      'Ingresa usuario/correo y contraseña';
  static const String anonymousError = 'Error en acceso anónimo';
  static const String convertAnonTitle = 'Vincular Cuenta Permanente';
  static const String convertAnonDesc =
      'Crea un usuario y contraseña para no perder tus datos al cerrar sesión.';

  static const String serverError = 'Error del servidor';
  static const String connectionError = 'Error de conexión';

  static const String tabFeed = 'Feed';
  static const String tabMessages = 'Mensajes';
  static const String tabSearch = 'Buscar';
  static const String tabProfile = 'Perfil';

  static const String myProfileTitle = 'Mi Perfil';
  static const String changePassword = 'Cambiar Contraseña';
  static const String logout = 'Cerrar Sesión';
  static const String newPasswordLabel = 'Nueva Contraseña';
  static const String passwordUpdated = 'Contraseña actualizada';
  static const String cancel = 'Cancelar';
  static const String save = 'Guardar';
  static const String myPostsSection = 'Publicaciones';
  static const String noUserPosts = 'No hay publicaciones de este usuario.';
  static const String noEmailAssigned = 'Sin correo asignado';
  static const String attachmentLabel = '📷 Adjunto:';
  static const String editBio = 'Editar Biografía';
  static const String bioHint = 'Escribe algo sobre ti...';
  static const String avatarUrlHint = 'URL de tu Avatar / Foto';
  static const String follow = 'Seguir';
  static const String unfollow = 'Siguiendo';

  static const String newPostTitle = 'Nueva Publicación';
  static const String editPostTitle = 'Editar Publicación';
  static const String newStoryTitle = 'Nueva Historia';
  static const String postHint = '¿Qué estás pensando? #hashtag';
  static const String storyHint = 'Escribe tu historia...';
  static const String mediaUrlLabel = 'URL de Foto/Video (Opcional)';
  static const String imageType = 'Imagen';
  static const String videoType = 'Video';
  static const String publishAsStory = 'Publicar como Historia';
  static const String publishButton = 'Publicar';
  static const String noPostsYet = 'No hay publicaciones aún.';
  static const String postLinkCopied = 'Enlace de publicación copiado';
  static const String deletePost = 'Eliminar Publicación';
  static const String filterByHashtag = 'Filtrar por Hashtag / Tendencia';
  static const String allPosts = 'Todas las publicaciones';

  // Publicaciones temporales y restricciones de invitados
  static const String anonCannotPost =
      'Los invitados/incógnitos no pueden crear publicaciones. Crea o vincula una cuenta en tu Perfil.';
  static const String tempPostLabel = 'Publicación temporal';
  static const String tempPostPermanent = 'No (Permanente)';
  static const String tempPost1h = 'Sí — 1 hora';
  static const String tempPost6h = 'Sí — 6 horas';
  static const String tempPost12h = 'Sí — 12 horas';
  static const String tempPost24h = 'Sí — 24 horas';
  static const String postExpired = 'Expirada';
  static const String lessThanOneMin = 'Menos de 1 min';
  static String remainingHoursMins(int h, int m) =>
      m > 0 ? 'Quedan ${h}h ${m}m' : 'Quedan ${h}h';
  static String remainingMins(int m) => 'Quedan $m min';

  // Chats grupales y rachas compartidas
  static const String newGroupBtn = 'Nuevo grupo';
  static const String newGroupDialogTitle = 'Nuevo grupo';
  static const String groupNameLabel = 'Nombre del grupo';
  static const String groupNameHint = 'Ej. Equipo Gym, Reto 30 días...';
  static const String groupMembersLabel = 'Integrantes:';
  static const String groupNoMutualFriends =
      'Solo puedes agregar usuarios que no sean incógnitos y con quienes te sigas mutuamente.';
  static const String createGroupBtn = 'Crear grupo';
  static const String defaultGroupTitle = 'Grupo';
  static const String sharedStreakTitle = 'Racha y Actividad Compartida';
  static const String sharedStreakSubtitle =
      'Cuando todos los integrantes registran hoy, la racha sube +1.';
  static const String workoutCategoryLabel = 'Ejercicio / Rutina';
  static const String dietCategoryLabel = 'Dieta / Comida';
  static const String shareAsFullRoutine = 'Compartir como rutina completa';
  static const String shareRoutineSubtitle = 'Ej. Push/Pull/Legs, 5K, HIIT...';
  static const String routineDetailsHint =
      'Describe ejercicios, series o tiempos';
  static const String workoutNoteHint = 'Nota opcional (ej. 45 min fuerza)';
  static const String dietNoteHint = '¿Qué comiste hoy? (opcional)';
  static const String logSharedActivityBtn = 'Registrar cumplimiento y enviar';
  static const String routineSharedPrefix = '📋 Rutina compartida - ';
  static const String sharedActivityTooltip =
      'Registrar ejercicio/dieta o compartir rutina';
  static const String emptyChatHint =
      'Inicia la conversación o registra tu rutina.';
  static const String workoutStreakShort = 'Ejercicio';
  static const String dietStreakShort = 'Dieta';
  static const String workoutCheckinLog =
      '🔥 Completó su rutina/ejercicio del día';
  static const String dietCheckinLog = '🥗 Cumplió su dieta saludable del día';
  static String groupCreatedLastMsg(String creator, String name) =>
      '$creator creó el grupo "$name"';
  static String groupCreatedSystemMsg(String name) =>
      '👋 Grupo "$name" creado. ¡Completen sus rutinas y dietas juntos para subir la racha!';

  static const String yourStory = 'Tu historia';
  static const String storyFrom = 'Historia de';
  static const String replyToStoryBtn = 'Responder al Chat';
  static const String replyToStoryTitle = 'Responder historia de';
  static const String directMessageHint = 'Envía un mensaje directo...';
  static const String sendButton = 'Enviar';
  static const String anonNoChat =
      'Los invitados anónimos no tienen acceso a chats.';

  static const String commentsTitle = 'Comentarios';
  static const String noCommentsYet = 'Aún no hay comentarios.';
  static const String commentHint = 'Escribe un comentario...';

  static const String directMessagesTitle = 'Mensajes Directos';
  static const String noActiveChats = 'No tienes conversaciones activas aún.';
  static const String searchUserHint = 'Buscar usuario...';
  static const String noUsersFound = 'No se encontraron usuarios.';
  static const String anonNoMessagesView =
      'Inicia sesión para usar los mensajes directos';
  static const String anonNoSearchView =
      'Inicia sesión para buscar otros usuarios';
  static const String newMessageFrom = 'Nuevo mensaje de';
  static const String isTyping = 'Escribiendo...';

  static const String anonymousUser = 'Anónimo';

  // Rutinas y métricas fitness
  static const String routineWeights = 'Pesas / Fuerza';
  static const String routineCardio = 'Cardio / Correr';
  static const String routineHiit = 'HIIT / Crossfit';
  static const String routineCycling = 'Ciclismo';
  static const String routineWalking = 'Caminata';
  static const String routineYoga = 'Yoga / Movilidad';

  static const String postCategoryTitle = 'Categoría de publicación:';
  static const String workoutTabLabel = 'Ejercicio';
  static const String foodTabLabel = 'Comida';
  static const String workoutContentHint =
      'Describe tu rutina, series o ejercicios... #gym';
  static const String foodContentHint = 'Describe tu comida o macros... #dieta';
  static const String activeRoutineLabel = 'Tipo de rutina activa';
  static const String durationMinsLabel = 'Tiempo (min)';
  static const String durationMinsHint = 'Ej: 45';
  static const String burnedKcalLabel = 'Kcal quemadas';
  static const String kcalAutoEmptyHint = 'Auto si vacío';
  static String kcalAutoEstimateHint(int kcal) => 'Auto: ~$kcal';
  static const String foodCaloriesLabel =
      'Calorías aprox. de la comida (Opcional)';
  static const String foodCaloriesHint = 'Ej: 550';
  static const String healthyDietSwitchLabel =
      'Comida saludable (Suma racha de dieta)';
  static const String healthyFoodBadge = 'Comida Saludable';
  static const String freeFoodBadge = 'Comida Libre';
  static String filteredByHashtag(String tag) => 'Filtrado por: $tag';

  // Notificaciones, búsqueda, listas y perfil
  static const String notifChannelDesc =
      'Notificaciones de nuevos mensajes de chat';
  static String newMessageTitle(String sender) => 'Nuevo mensaje de $sender';
  static const String typeToSearchUsers = 'Escribe para buscar usuarios';
  static const String clearAllBtn = 'Borrar todo';
  static const String emptyListText = 'Lista vacía';
  static const String workoutStreakTitle = 'Racha Ejercicio';
  static const String dietStreakTitle = 'Racha Dieta';
  static const String linkAccountBtn = 'Vincular Cuenta';
  static String linkAccountError(Object e) => 'Error al vincular: $e';
  static String groupTitleWithCount(int count) => 'Grupo ($count)';
  static String groupMembersDetail(int count, String members) =>
      'Integrantes ($count): $members';

  // Registro ampliado
  static const String registerNameLabel = 'Nombre de usuario';
  static const String optionalEmailLabel = 'Correo electrónico (Opcional)';
  static const String confirmPasswordLabel = 'Comprobar contraseña';
  static const String emptyNameOrPasswordError =
      'Ingresa un nombre de usuario y una contraseña';
  static const String invalidOptionalEmailError =
      'Ingresa un correo electrónico válido o déjalo vacío';
  static const String passwordsDoNotMatchError = 'Las contraseñas no coinciden';
  static const String usernameAlreadyExistsError =
      'Ese nombre de usuario ya está en uso';

  // Rutina semanal (7 días)
  static const String weeklyRoutineTitle = 'Rutina Semanal (7 Días)';
  static const String weeklyRoutineSubtitle =
      'Toca un día para ver o editar la rutina';
  static const List<String> weekDaysShort = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];
  static const List<String> weekDaysFull = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const String restDayLabel = 'Día de descanso / Recuperación';
  static const String editDayRoutineTitle = 'Editar rutina del día';
  static const String dayFocusHint =
      'Enfoque (ej. Pecho y Tríceps, Pierna, Descanso)';
  static const String dayExercisesHint =
      'Ejercicios y series (uno por línea)...';
  static const String noExercisesRegistered =
      'Sin ejercicios detallados para este día.';

  // Modo Entrenamiento en vivo y temporizadores
  static const String liveWorkoutTitle = 'Modo Entrenamiento';
  static const String liveWorkoutActiveBadge = 'ENTRENANDO AHORA';
  static const String liveWorkoutInactiveSub =
      'Actívalo para mostrar qué entrenas y usar temporizadores';
  static const String currentExerciseLabel = 'Ejercicio actual';
  static const String currentExerciseHint =
      'Ej. Press Banca, Sentadillas, Trote 5K...';
  static const String updateExerciseBtn = 'Actualizar';
  static const String restTimerTitle = 'Descanso entre series';
  static const String waterTimerTitle = 'Recordatorio de agua';
  static const String drinkWaterAlert =
      '💧 ¡Hora de tomar agua! Mantente hidratado.';
  static const String restFinishedAlert =
      '⏱️ ¡Tiempo de descanso terminado! Siguiente serie.';
  static const String finishWorkoutBtn = 'Finalizar entrenamiento';
  static const String publishWorkoutPromptTitle = '¿Publicar entrenamiento?';
  static const String publishWorkoutPromptBody =
      '¿Quieres compartir tu sesión como una publicación temporal (24h) en el feed?';
  static const String publishAsTemp24hBtn = 'Publicar temporal (24h)';
  static const String justFinishBtn = 'Solo finalizar';

  // Logros, PRs y Evolución
  static const String achievementsAndPrsTitle = 'Logros, PRs y Evolución';
  static const String totalKmLabel = 'Km Totales';
  static const String totalWorkoutsLabel = 'Sesiones';
  static const String addCustomPrBtn = 'Registrar PR / Ejercicio';
  static const String exerciseNameLabel = 'Nombre del ejercicio';
  static const String exerciseNameHint =
      'Ej. Press Banca, Dominadas, Carrera 10K...';
  static const String prValueLabel = 'Marca / Récord (kg, reps o km)';
  static const String prValueHint = 'Ej. 100 kg, 15 reps, 10.5 km';
  static const String prNotesLabel = 'Notas o evolución (opcional)';
  static const String noPrsYet = 'Aún no hay récords personales registrados.';

  // Subida de fotos sin servidor externo (Base64 optimizado)
  static const String pickFromGalleryBtn = 'Subir foto (Galería)';
  static const String takePhotoBtn = 'Cámara';
  static const String photoAttachedBadge = 'Foto adjunta lista para publicar';
  static const String photoTooLargeError =
      'La imagen es demasiado pesada, intenta con otra.';

  // Feed filtrado y notificaciones
  static const String feedExploreTab = 'Explorar';
  static const String feedFollowingTab = 'Siguiendo';
  static const String noFollowingPosts =
      'Aún no hay publicaciones de las personas que sigues.';
  static const String notificationsTitle = 'Notificaciones';
  static const String noNotificationsYet = 'No tienes notificaciones nuevas.';
  static const String markAllReadBtn = 'Marcar leídas';

  // Ranking / Mejores de la aplicación (Opt-in)
  static const String leaderboardTitle = 'Mejores de Gym-Book (Ranking)';
  static const String participateLeaderboardLabel = 'Participar en el ranking';
  static const String participateLeaderboardSub =
      'Muestra tu progreso en la tabla global de la comunidad';
  static const String noLeaderboardParticipants =
      'Aún no hay atletas inscritos en el ranking.';
  static const String followingFilterChip = 'Siguiendo';

  // Acceso directo al ranking y detalles en chats
  static const String openRankingTooltip = 'Ver ranking de mejores atletas';
  static const String groupNameRequiredError =
      'Debes ingresar un nombre para el grupo';
  static const String groupMembersRequiredError =
      'Selecciona al menos un integrante';
  static const String tapHeaderForDetailsHint =
      'Toca aquí para ver actividad y perfiles';
  static const String chatActivitySummaryTitle = 'Actividad y Resumen';
  static const String groupParticipantsTitle = 'Integrantes del grupo';
  static const String viewProfileBtn = 'Ver perfil';
  static const String trainingNowLabel = 'Entrenando ahora';
  static const String inactiveNowLabel = 'Sin entrenamiento activo';
  static const String quickTrainToggleTooltip =
      'Activar / editar mi modo entrenamiento';

  // Foto y Video de Perfil en Firestore
  static const String pickAvatarPhotoBtn = 'Foto galería';
  static const String takeAvatarPhotoBtn = 'Cámara';
  static const String pickAvatarVideoBtn = 'Video (máx 6s)';
  static const String avatarVideoTooLargeError =
      'El video supera 650 KB. Graba uno más corto (3-5 s) o en menor resolución.';
  static const String avatarMediaReadyBadge =
      'Multimedia de perfil lista para guardar';
  static const String tapAvatarToChangeHint =
      'Toca el avatar para cambiar foto o video';

  // Menciones @ y restricción de incógnitos
  static const String anonCannotLikeOrComment =
      'Inicia sesión con una cuenta para dar me gusta o comentar';
  static const String anonCommentRestrictedHint =
      'Los perfiles incógnito solo pueden leer comentarios';
  static const String mentionSuggestionTitle = 'Mencionar usuario:';
}
