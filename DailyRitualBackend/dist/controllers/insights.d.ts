import { Request, Response } from 'express';
export declare class InsightsController {
    static getInsights(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static markAsRead(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getInsightsStats(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
//# sourceMappingURL=insights.d.ts.map