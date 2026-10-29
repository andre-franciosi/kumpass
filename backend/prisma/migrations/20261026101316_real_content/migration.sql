-- AlterTable
ALTER TABLE "Checkpoint" ADD COLUMN     "imageCredit" TEXT,
ADD COLUMN     "imageUrl" TEXT,
ADD COLUMN     "loreSource" TEXT,
ADD COLUMN     "loreUrl" TEXT;

-- AlterTable
ALTER TABLE "Quest" ADD COLUMN     "imageCredit" TEXT;
