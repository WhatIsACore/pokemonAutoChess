#!/bin/sh
# Allows any room owner (not just admins) to set special game rules.
# Run before `npm run build`.

# Server: remove admin role check, keep owner check
sed -i 's/client.auth?.uid == this.state.ownerId && u.role === Role.ADMIN/client.auth?.uid == this.state.ownerId/' app/rooms/commands/preparation-commands.ts

# Client: remove isAdmin and custom lobby gate, keep noElo requirement
sed -i 's/gameMode === GameMode.CUSTOM_LOBBY &&//' app/public/src/pages/component/preparation/preparation-menu.tsx
sed -i 's/isAdmin &&//' app/public/src/pages/component/preparation/preparation-menu.tsx
