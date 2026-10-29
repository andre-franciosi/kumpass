-- AlterTable
ALTER TABLE "User" ADD COLUMN     "isTest" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "TrailMessage" (
    "id" TEXT NOT NULL,
    "questId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "lat" DOUBLE PRECISION NOT NULL,
    "lng" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3),
    "likeCount" INTEGER NOT NULL DEFAULT 0,
    "reportCount" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "TrailMessage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrailMessageLike" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TrailMessageLike_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrailMessageReport" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TrailMessageReport_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "TrailMessage_questId_createdAt_idx" ON "TrailMessage"("questId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "TrailMessageLike_userId_messageId_key" ON "TrailMessageLike"("userId", "messageId");

-- CreateIndex
CREATE UNIQUE INDEX "TrailMessageReport_userId_messageId_key" ON "TrailMessageReport"("userId", "messageId");

-- AddForeignKey
ALTER TABLE "TrailMessage" ADD CONSTRAINT "TrailMessage_questId_fkey" FOREIGN KEY ("questId") REFERENCES "Quest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrailMessage" ADD CONSTRAINT "TrailMessage_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrailMessageLike" ADD CONSTRAINT "TrailMessageLike_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "TrailMessage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrailMessageLike" ADD CONSTRAINT "TrailMessageLike_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrailMessageReport" ADD CONSTRAINT "TrailMessageReport_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "TrailMessage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrailMessageReport" ADD CONSTRAINT "TrailMessageReport_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
