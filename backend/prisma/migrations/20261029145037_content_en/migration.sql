-- AlterTable
ALTER TABLE "Checkpoint" ADD COLUMN     "loreEn" TEXT,
ADD COLUMN     "loreSourceEn" TEXT,
ADD COLUMN     "loreUrlEn" TEXT,
ADD COLUMN     "titleEn" TEXT;

-- AlterTable
ALTER TABLE "Quest" ADD COLUMN     "descriptionEn" TEXT,
ADD COLUMN     "titleEn" TEXT;
