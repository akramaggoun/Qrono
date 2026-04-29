-- CreateTable
CREATE TABLE "exclusions" (
    "id" TEXT NOT NULL,
    "student_id" TEXT NOT NULL,
    "professor_id" TEXT NOT NULL,
    "course_name" TEXT NOT NULL,
    "reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "exclusions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "exclusions_student_id_professor_id_course_name_key" ON "exclusions"("student_id", "professor_id", "course_name");

-- AddForeignKey
ALTER TABLE "exclusions" ADD CONSTRAINT "exclusions_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exclusions" ADD CONSTRAINT "exclusions_professor_id_fkey" FOREIGN KEY ("professor_id") REFERENCES "professors"("id") ON DELETE CASCADE ON UPDATE CASCADE;
