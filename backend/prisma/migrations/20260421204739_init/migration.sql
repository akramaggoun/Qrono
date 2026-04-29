-- DropForeignKey
ALTER TABLE "schedules" DROP CONSTRAINT "schedules_created_by_admin_id_fkey";

-- AddForeignKey
ALTER TABLE "schedules" ADD CONSTRAINT "schedules_created_by_admin_id_fkey" FOREIGN KEY ("created_by_admin_id") REFERENCES "admins"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;
