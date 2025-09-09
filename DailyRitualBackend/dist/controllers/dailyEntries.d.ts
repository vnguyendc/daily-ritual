import { Request, Response } from 'express';
export declare class DailyEntriesController {
    static getDailyEntry(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getDailyEntryWithPlans(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getDailyQuote(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static completeMorningRitual(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static completeEveningReflection(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getDailyEntries(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static deleteDailyEntry(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
//# sourceMappingURL=dailyEntries.d.ts.map