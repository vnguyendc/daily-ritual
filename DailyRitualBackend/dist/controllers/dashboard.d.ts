import { Request, Response } from 'express';
export declare class DashboardController {
    static getDashboardData(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    private static getWeeklyStats;
    static getUserProfile(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static updateUserProfile(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getUserStreaks(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getAIInsights(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static markInsightAsRead(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static generateWeeklyInsights(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
//# sourceMappingURL=dashboard.d.ts.map