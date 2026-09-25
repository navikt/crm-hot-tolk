import { LightningElement, wire } from 'lwc';
import getTransferredServiceAppointmentsCount from '@salesforce/apex/HOT_TjenesteleverandorListController.getTransferredServiceAppointmentsCount';
import getNumberOfUnreadThreads from '@salesforce/apex/HOT_TLThreadlistController.getNumberOfUnreadThreads';

const ANIMATION_DURATION_MS = 1000;

export default class Hot_tjenesteleverandorStatistics extends LightningElement {
    statistics = [
        {
            id: 'assignments',
            value: 0,
            displayValue: 0,
            label: 'Oppdrag som venter på å bli akseptert eller avslått'
        },
        {
            id: 'unreadMessages',
            value: 0,
            displayValue: 0,
            label: 'uleste meldinger, og 0 samtaler er dine'
        }
    ];

    connectedCallback() {
        this.animateStatistic('unreadMessages');
    }
    @wire(getNumberOfUnreadThreads)
    wiredUnreadThreads({ data, error }) {
        if (data === undefined && error === undefined) {
            return;
        }
        const allUnreadCount = error ? 0 : (data.allUnread ?? 0);
        const myUnreadCount = error ? 0 : (data.myUnread ?? 0);

        this.statistics = this.statistics.map((statistic) =>
            statistic.id === 'unreadMessages'
                ? {
                      ...statistic,
                      value: allUnreadCount,
                      label: `uleste meldinger, og ${myUnreadCount} samtaler er dine`
                  }
                : statistic
        );
        this.animateStatistic('unreadMessages');
    }

    @wire(getTransferredServiceAppointmentsCount)
    wiredTransferredCount({ data, error }) {
        if (data === undefined && error === undefined) {
            return;
        }
        const count = error ? 0 : data;
        this.statistics = this.statistics.map((statistic) =>
            statistic.id === 'assignments' ? { ...statistic, value: count } : statistic
        );
        this.animateStatistic('assignments');
    }

    animateStatistic(id) {
        const target = this.statistics.find((statistic) => statistic.id === id)?.value ?? 0;
        const startTime = performance.now();

        const step = (currentTime) => {
            const progress = Math.min((currentTime - startTime) / ANIMATION_DURATION_MS, 1);

            this.statistics = this.statistics.map((statistic) =>
                statistic.id === id ? { ...statistic, displayValue: Math.round(target * progress) } : statistic
            );

            if (progress < 1) {
                requestAnimationFrame(step);
            }
        };

        requestAnimationFrame(step);
    }
}
